#include <QApplication>
#include "vinxi18n.h"
#include <QCommandLineParser>
#include <QDir>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>
#include <QUrl>

#include "foldermodel.h"
#include "themeicons.h"

// Fichiers : gestionnaire de fichiers de VinX OS. QApplication : les dialogues KIO
// (conflits de noms, « Ouvrir avec ») sont des fenêtres Qt Widgets.
int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    vinxInstallTranslator(app);
    app.setApplicationName(QStringLiteral("vinx-files"));
    app.setApplicationDisplayName(QObject::tr("Fichiers"));
    app.setApplicationVersion(QStringLiteral(VINX_VERSION));
    app.setDesktopFileName(QStringLiteral("org.vinx.files"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("system-file-manager")));

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption shot(QStringLiteral("screenshot"), QStringLiteral("Enregistre une capture puis quitte."), QStringLiteral("fichier"));
    parser.addOption(shot);
    parser.addPositionalArgument(QStringLiteral("emplacement"), QStringLiteral("Dossier ou URL à ouvrir."));
    parser.process(app);

    QUrl start = QUrl::fromLocalFile(QDir::homePath());
    if (!parser.positionalArguments().isEmpty()) {
        const QString arg = parser.positionalArguments().constFirst();
        start = QUrl::fromUserInput(arg, QDir::currentPath(), QUrl::AssumeLocalFile);
        // Un fichier passé en argument : on ouvre son dossier et on le sélectionne.
        if (start.isLocalFile() && QFileInfo(start.toLocalFile()).isFile())
            start = QUrl::fromLocalFile(QFileInfo(start.toLocalFile()).absolutePath());
    }

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("theme"), new ThemeIconProvider);
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
    if (QDir(QStringLiteral(VINX_BUILD_QML_DIR)).exists())
        engine.addImportPath(QStringLiteral(VINX_BUILD_QML_DIR));
    engine.setInitialProperties({{QStringLiteral("startUrl"), start}});
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Vinx/Files/Main.qml")));

    if (parser.isSet(shot) && !engine.rootObjects().isEmpty()) {
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
        const QString file = parser.value(shot);
        QTimer::singleShot(1200, &app, [window, file] { QCoreApplication::exit(window && window->grabWindow().save(file) ? 0 : 2); });
    }
    return app.exec();
}
