// vinx-shell — shell de bureau de VinX OS.
//
// Session Wayland (KWin) : la barre et sa couche de panneaux sont des surfaces layer-shell.
// Ailleurs (X11, développement, --preview) : une seule fenêtre d'aperçu.

#include <QCommandLineParser>
#include <QDir>
#include <QHash>
#include <QPointer>
#include <QScreen>
#include <QGuiApplication>
#include <QIcon>
#include <QQuickImageProvider>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickWindow>
#include <QTimer>

// Icônes du thème système pour les applications sans icône VinX : image://theme/<nom>
class ThemeIconProvider : public QQuickImageProvider
{
public:
    ThemeIconProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requested) override
    {
        const QSize s = requested.isValid() ? requested : QSize(64, 64);
        const QIcon icon = QIcon::fromTheme(id);
        // Pixmap vide si l'icône est absente : le QML affiche alors un pictogramme VinX.
        const QPixmap pm = icon.isNull() ? QPixmap() : icon.pixmap(s);
        if (size)
            *size = pm.size();
        return pm;
    }
};

#ifdef VINX_HAVE_LAYERSHELL
#include <LayerShellQt/Window>

static void configureLayer(QWindow *window, LayerShellQt::Window::Layer level, LayerShellQt::Window::Anchors anchors,
                           int exclusiveZone, LayerShellQt::Window::KeyboardInteractivity keyboard, const QString &scope)
{
    auto *layer = LayerShellQt::Window::get(window);
    layer->setLayer(level);
    layer->setAnchors(anchors);
    layer->setExclusiveZone(exclusiveZone);
    layer->setKeyboardInteractivity(keyboard);
    layer->setScope(scope);
}
#endif

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("vinx-shell"));
    app.setApplicationVersion(QStringLiteral(VINX_VERSION));
    app.setDesktopFileName(QStringLiteral("org.vinx.shell"));
    app.setQuitOnLastWindowClosed(false);

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Shell de bureau de VinX OS"));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption preview(QStringLiteral("preview"), QStringLiteral("Affiche le shell dans une fenêtre d'aperçu."));
    const QCommandLineOption light(QStringLiteral("light"), QStringLiteral("Démarre en thème clair."));
    const QCommandLineOption open(QStringLiteral("open"), QStringLiteral("Ouvre un panneau : system, control ou calendar."), QStringLiteral("panneau"));
    const QCommandLineOption shot(QStringLiteral("screenshot"), QStringLiteral("Aperçu : enregistre une capture puis quitte."), QStringLiteral("fichier"));
    const QCommandLineOption demo(QStringLiteral("demo"), QStringLiteral("Aperçu : simule quelques fenêtres ouvertes."));
    parser.addOptions({preview, light, open, shot, demo});
    parser.process(app);

    if (QIcon::themeName().isEmpty() || QIcon::themeName() == QLatin1String("hicolor"))
        QIcon::setThemeName(QStringLiteral("breeze-dark"));

    QQmlEngine engine;
    engine.addImageProvider(QStringLiteral("theme"), new ThemeIconProvider);
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
    if (QDir(QStringLiteral(VINX_BUILD_QML_DIR)).exists())
        engine.addImportPath(QStringLiteral(VINX_BUILD_QML_DIR));

    // Les composants vivent dans le plugin du module Vinx.Shell : on les instancie via un import.
    const auto create = [&engine](const char *type, const QVariantMap &props = {}) -> QWindow * {
        QQmlComponent component(&engine);
        component.setData(QByteArray("import Vinx.Shell\n") + type + " {}", QUrl());
        QObject *object = component.isReady() ? component.createWithInitialProperties(props) : nullptr;
        if (!object)
            qCritical().noquote() << "vinx-shell: impossible de créer" << type << component.errorString();
        return qobject_cast<QWindow *>(object);
    };

    bool layerShell = false;
#ifdef VINX_HAVE_LAYERSHELL
    layerShell = !parser.isSet(preview) && !parser.isSet(shot) && QGuiApplication::platformName().startsWith(QLatin1String("wayland"));
#endif

    if (!layerShell) {
        app.setQuitOnLastWindowClosed(true);
        auto *window = qobject_cast<QQuickWindow *>(create("Preview", {
            {QStringLiteral("startLight"), parser.isSet(light)},
            {QStringLiteral("startOpen"), parser.value(open)},
            {QStringLiteral("demo"), parser.isSet(demo)},
        }));
        if (!window)
            return 1;
        if (parser.isSet(shot)) {
            const QString file = parser.value(shot);
            QTimer::singleShot(900, &app, [window, file] {
                QCoreApplication::exit(window && window->grabWindow().save(file) ? 0 : 2);
            });
        }
        return app.exec();
    }

#ifdef VINX_HAVE_LAYERSHELL
    using LSW = LayerShellQt::Window;
    // Ce processus est le serveur de notifications de la session (org.freedesktop.Notifications).
    qputenv("VINX_SHELL_PROCESS", "1");
    const auto all = LSW::Anchors(LSW::AnchorTop | LSW::AnchorBottom | LSW::AnchorLeft | LSW::AnchorRight);
    const auto onScreen = [](QScreen *screen, bool primary = true) {
        return QVariantMap{{QStringLiteral("screen"), QVariant::fromValue(screen)}, {QStringLiteral("isPrimary"), primary}};
    };

    // ---------- Par écran : fond d'écran, barre, couche des panneaux ----------
    struct ScreenWindows {
        QPointer<QWindow> background, bar, panels;
    };
    QHash<QScreen *, ScreenWindows> perScreen;

    const auto addScreen = [&](QScreen *screen) {
        if (perScreen.contains(screen))
            return;
        const bool primary = screen == QGuiApplication::primaryScreen();
        ScreenWindows w;
        w.background = create("BackgroundWindow", {{QStringLiteral("screen"), QVariant::fromValue(screen)}});
        w.bar = create("TopBarWindow", {{QStringLiteral("screen"), QVariant::fromValue(screen)}, {QStringLiteral("isPrimary"), primary}});
        w.panels = create("PopupWindow", onScreen(screen, primary));
        if (!w.background || !w.bar || !w.panels)
            return;
        // Fond : sous toutes les fenêtres ; clavier à la demande (note rapide du bureau).
        configureLayer(w.background, LSW::LayerBackground, all, -1, LSW::KeyboardInteractivityOnDemand, QStringLiteral("vinx-background"));
        // Barre : en haut sur toute la largeur, réserve sa hauteur.
        configureLayer(w.bar, LSW::LayerTop, LSW::Anchors(LSW::AnchorTop | LSW::AnchorLeft | LSW::AnchorRight),
                       w.bar->height(), LSW::KeyboardInteractivityOnDemand, QStringLiteral("vinx-topbar"));
        // Panneaux : plein écran au-dessus de tout, clavier exclusif tant qu'ils sont visibles.
        configureLayer(w.panels, LSW::LayerOverlay, all, -1, LSW::KeyboardInteractivityExclusive, QStringLiteral("vinx-panels"));
        w.background->show();
        w.bar->show();
        perScreen.insert(screen, w);
    };
    const auto removeScreen = [&](QScreen *screen) {
        const ScreenWindows w = perScreen.take(screen);
        for (QWindow *win : {w.background.data(), w.bar.data(), w.panels.data()})
            if (win)
                win->deleteLater();
    };
    for (QScreen *screen : QGuiApplication::screens())
        addScreen(screen);
    QObject::connect(&app, &QGuiApplication::screenAdded, &app, addScreen);
    QObject::connect(&app, &QGuiApplication::screenRemoved, &app, removeScreen);

    // ---------- Écran principal : dock et bulles de notification ----------
    QPointer<QWindow> dock, toasts;
    const auto placeOnPrimary = [&]() {
        QScreen *primary = QGuiApplication::primaryScreen();
        if (dock) dock->deleteLater();
        if (toasts) toasts->deleteLater();
        dock = create("DockWindow", {{QStringLiteral("screen"), QVariant::fromValue(primary)}});
        toasts = create("ToastWindow", {{QStringLiteral("screen"), QVariant::fromValue(primary)}});
        if (!dock || !toasts)
            return;
        // Dock : en bas au centre ; réserve la hauteur de son plateau.
        configureLayer(dock, LSW::LayerTop, LSW::Anchors(LSW::AnchorBottom), dock->property("reservedHeight").toInt(),
                       LSW::KeyboardInteractivityNone, QStringLiteral("vinx-dock"));
        // Bulles : en haut à droite, sous la barre, sans zone réservée.
        configureLayer(toasts, LSW::LayerTop, LSW::Anchors(LSW::AnchorTop | LSW::AnchorRight), 0,
                       LSW::KeyboardInteractivityNone, QStringLiteral("vinx-notifications"));
        dock->show();
        toasts->show();
    };
    placeOnPrimary();
    QObject::connect(&app, &QGuiApplication::primaryScreenChanged, &app, placeOnPrimary);
#endif
    return app.exec();
}
