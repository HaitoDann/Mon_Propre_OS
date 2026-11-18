#include <QCommandLineParser>
#include <QDir>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QtQml/qqml.h>
#include <QQuickWindow>
#include <QTimer>

#include "shot.h"
#include "vinxi18n.h"

// Capture d'écran VinX (ADR 0036).
//   vinx-screenshot            Méta+Maj+S : zone, fenêtre ou écran, puis annotation
//   vinx-screenshot --full     Impr. écran : tout l'écran, copié et enregistré
//   vinx-screenshot --edit F   annoter une image
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    vinxInstallTranslator(app);
    app.setApplicationName(QStringLiteral("vinx-screenshot"));
    app.setApplicationVersion(QStringLiteral(VINX_VERSION));
    app.setDesktopFileName(QStringLiteral("org.vinx.screenshot"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("applets-screenshooter")));
    app.setQuitOnLastWindowClosed(false);   // les fenêtres de sélection se cachent pendant le retardateur

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption full(QStringLiteral("full"), QStringLiteral("Capture tout l'écran, la copie et l'enregistre."));
    const QCommandLineOption edit(QStringLiteral("edit"), QStringLiteral("Annoter une image."), QStringLiteral("fichier"));
    const QCommandLineOption image(QStringLiteral("image"), QStringLiteral("Image utilisée à la place de l'écran (tests)."), QStringLiteral("fichier"));
    const QCommandLineOption area(QStringLiteral("area"), QStringLiteral("Zone présélectionnée x,y,l,h (tests)."), QStringLiteral("zone"));
    const QCommandLineOption shot(QStringLiteral("screenshot"), QStringLiteral("Enregistre une capture de la fenêtre puis quitte."), QStringLiteral("fichier"));
    parser.addOptions({full, edit, image, area, shot});
    parser.process(app);
    if (parser.isSet(image))
        qputenv("VINX_SCREENSHOT_IMAGE", parser.value(image).toUtf8());

    const QString mode = parser.isSet(edit) ? QStringLiteral("edit") : parser.isSet(full) ? QStringLiteral("full") : QStringLiteral("select");
    Shot *capture = Shot::instance();
    capture->setMode(mode);

    qmlRegisterSingletonInstance("Vinx.Screenshot", 1, 0, "Shot", capture);
    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("shot"), new ShotImageProvider);
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
    if (QDir(QStringLiteral(VINX_BUILD_QML_DIR)).exists())
        engine.addImportPath(QStringLiteral(VINX_BUILD_QML_DIR));
    engine.setInitialProperties({{QStringLiteral("startMode"), mode}});
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Vinx/Screenshot/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return 1;
    QObject *root = engine.rootObjects().constFirst();

    if (mode == QLatin1String("edit")) {
        if (!capture->load(parser.value(edit))) {
            qWarning("Image illisible : %s", qPrintable(parser.value(edit)));
            return 1;
        }
    } else if (mode == QLatin1String("full")) {
        capture->takeWorkspace();
    } else {
        const QStringList a = parser.value(area).split(QLatin1Char(','));
        if (a.size() == 4) {
            QObject::connect(capture, &Shot::screensReady, root, [root, a, capture] {
                const QString screen = capture->screens().value(0).toMap().value(QStringLiteral("name")).toString();
                root->setProperty("selection", QVariantMap{{QStringLiteral("screen"), screen}, {QStringLiteral("x"), a[0].toDouble()},
                                                           {QStringLiteral("y"), a[1].toDouble()}, {QStringLiteral("width"), a[2].toDouble()},
                                                           {QStringLiteral("height"), a[3].toDouble()}});
            }, Qt::SingleShotConnection);
        }
        capture->grabScreens();
    }

    if (parser.isSet(shot)) {
        const QString file = parser.value(shot);
        QTimer::singleShot(1500, &app, [file] {
            for (QWindow *w : QGuiApplication::topLevelWindows()) {
                auto *q = qobject_cast<QQuickWindow *>(w);
                if (q && q->isVisible()) {
                    QCoreApplication::exit(q->grabWindow().save(file) ? 0 : 2);
                    return;
                }
            }
            QCoreApplication::exit(3);
        });
    }
    return app.exec();
}
