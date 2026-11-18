#include <QCommandLineParser>
#include <QDir>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>
#include <QUrl>
#include <QtQml/qqml.h>

#include "viewer.h"
#include "vinxi18n.h"

// Visionneur d'images VinX (ADR 0038) : vinx-images [--edit] image
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    vinxInstallTranslator(app);
    app.setApplicationName(QStringLiteral("vinx-images"));
    app.setApplicationVersion(QStringLiteral(VINX_VERSION));
    app.setDesktopFileName(QStringLiteral("org.vinx.images"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("image-x-generic")));

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption edit(QStringLiteral("edit"), QStringLiteral("Ouvrir directement en mode Modifier."));
    const QCommandLineOption info(QStringLiteral("info"), QStringLiteral("Afficher le panneau Infos (captures)."));
    const QCommandLineOption shot(QStringLiteral("screenshot"), QStringLiteral("Enregistre une capture puis quitte."), QStringLiteral("fichier"));
    parser.addOptions({edit, info, shot});
    parser.addPositionalArgument(QStringLiteral("image"), QStringLiteral("Image à ouvrir."));
    parser.process(app);

    Viewer *viewer = Viewer::instance();
    if (!parser.positionalArguments().isEmpty()) {
        const QString arg = parser.positionalArguments().constFirst();
        const QUrl url = QUrl::fromUserInput(arg, QDir::currentPath(), QUrl::AssumeLocalFile);
        viewer->open(url.isLocalFile() ? url.toLocalFile() : arg);
    }

    qmlRegisterSingletonInstance("Vinx.Viewer", 1, 0, "Viewer", viewer);
    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("photo"), new PhotoImageProvider);
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
    if (QDir(QStringLiteral(VINX_BUILD_QML_DIR)).exists())
        engine.addImportPath(QStringLiteral(VINX_BUILD_QML_DIR));
    engine.setInitialProperties({{QStringLiteral("startMode"), parser.isSet(edit) ? QStringLiteral("edit") : QString()},
                                 {QStringLiteral("infoOpen"), parser.isSet(info)}});
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Vinx/Viewer/Main.qml")));

    if (parser.isSet(shot) && !engine.rootObjects().isEmpty()) {
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
        const QString file = parser.value(shot);
        QTimer::singleShot(1500, &app, [window, file] { QCoreApplication::exit(window && window->grabWindow().save(file) ? 0 : 2); });
    }
    return app.exec();
}
