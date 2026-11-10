#include <QCommandLineParser>
#include <QDir>
#include <QQuickWindow>
#include <QTimer>
#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("vinx-gallery"));
    app.setApplicationDisplayName(QStringLiteral("VinX — Design system"));
    app.setApplicationVersion(QStringLiteral(VINX_VERSION));
    app.setDesktopFileName(QStringLiteral("org.vinx.gallery"));

    // Options de recette visuelle (CI, documentation) :
    //   vinx-gallery --light --open cc --screenshot capture.png
    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption light(QStringLiteral("light"), QStringLiteral("Démarre en thème clair."));
    const QCommandLineOption open(QStringLiteral("open"), QStringLiteral("Ouvre un panneau : menu ou cc."), QStringLiteral("panneau"));
    const QCommandLineOption shot(QStringLiteral("screenshot"), QStringLiteral("Enregistre une capture puis quitte."), QStringLiteral("fichier"));
    parser.addOptions({light, open, shot});
    parser.process(app);

    QQmlApplicationEngine engine;
    engine.setInitialProperties({
        {QStringLiteral("startLight"), parser.isSet(light)},
        {QStringLiteral("startOpen"), parser.value(open)},
    });
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
    // Depuis le dossier de build, les modules Vinx.* sont dans build/qml/.
    if (QDir(QStringLiteral(VINX_BUILD_QML_DIR)).exists())
        engine.addImportPath(QStringLiteral(VINX_BUILD_QML_DIR));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Vinx/Gallery/Gallery.qml")));
    if (parser.isSet(shot)) {
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0));
        const QString file = parser.value(shot);
        QTimer::singleShot(800, &app, [window, file] {
            const bool ok = window && window->grabWindow().save(file);
            QCoreApplication::exit(ok ? 0 : 2);
        });
    }
    return app.exec();
}
