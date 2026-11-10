// vinx-shell — shell de bureau de VinX OS.
//
// Session Wayland (KWin) : la barre et sa couche de panneaux sont des surfaces layer-shell.
// Ailleurs (X11, développement, --preview) : une seule fenêtre d'aperçu.

#include <QCommandLineParser>
#include <QDir>
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
        QIcon icon = QIcon::fromTheme(id);
        if (icon.isNull())
            icon = QIcon::fromTheme(QStringLiteral("application-x-executable"));
        const QPixmap pm = icon.pixmap(s);
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
    QWindow *background = create("BackgroundWindow");
    QWindow *dock = create("DockWindow");
    QWindow *bar = create("TopBarWindow");
    QWindow *panels = create("PopupWindow");
    if (!background || !dock || !bar || !panels)
        return 1;
    const auto all = LSW::Anchors(LSW::AnchorTop | LSW::AnchorBottom | LSW::AnchorLeft | LSW::AnchorRight);

    // Fond d'écran : sous toutes les fenêtres.
    configureLayer(background, LSW::LayerBackground, all, -1, LSW::KeyboardInteractivityNone, QStringLiteral("vinx-background"));
    // Dock : en bas au centre ; réserve la hauteur de son plateau.
    configureLayer(dock, LSW::LayerTop, LSW::Anchors(LSW::AnchorBottom), dock->property("reservedHeight").toInt(),
                   LSW::KeyboardInteractivityNone, QStringLiteral("vinx-dock"));
    // Barre : ancrée en haut sur toute la largeur, réserve sa hauteur (les fenêtres s'arrêtent dessous).
    configureLayer(bar, LSW::LayerTop, LSW::Anchors(LSW::AnchorTop | LSW::AnchorLeft | LSW::AnchorRight),
                   bar->height(), LSW::KeyboardInteractivityOnDemand, QStringLiteral("vinx-topbar"));
    // Panneaux : couche plein écran au-dessus de tout, clavier exclusif tant qu'elle est visible.
    configureLayer(panels, LSW::LayerOverlay, all, -1, LSW::KeyboardInteractivityExclusive, QStringLiteral("vinx-panels"));
    background->show();
    dock->show();
    bar->show();
#endif
    return app.exec();
}
