#include <QCommandLineParser>
#include <QDir>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>

#include "themeicons.h"
#include "vinxi18n.h"

// Moniteur système VinX (ADR 0035).
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    vinxInstallTranslator(app);
    app.setApplicationName(QStringLiteral("vinx-monitor"));
    app.setApplicationVersion(QStringLiteral(VINX_VERSION));
    app.setDesktopFileName(QStringLiteral("org.vinx.monitor"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("utilities-system-monitor")));

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption shot(QStringLiteral("screenshot"), QStringLiteral("Enregistre une capture puis quitte."), QStringLiteral("fichier"));
    const QCommandLineOption search(QStringLiteral("search"), QStringLiteral("Recherche initiale."), QStringLiteral("texte"));
    parser.addOption(shot);
    parser.addOption(search);
    parser.process(app);

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("theme"), new ThemeIconProvider);
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
    if (QDir(QStringLiteral(VINX_BUILD_QML_DIR)).exists())
        engine.addImportPath(QStringLiteral(VINX_BUILD_QML_DIR));
    engine.setInitialProperties({{QStringLiteral("startQuery"), parser.value(search)}});
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Vinx/Monitor/Main.qml")));

    if (parser.isSet(shot) && !engine.rootObjects().isEmpty()) {
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
        const QString file = parser.value(shot);
        // Deux mesures (intervalle de 2 s) pour avoir des pourcentages.
        QTimer::singleShot(4600, &app, [window, file] { QCoreApplication::exit(window && window->grabWindow().save(file) ? 0 : 2); });
    }
    return app.exec();
}
