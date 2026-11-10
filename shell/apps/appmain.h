#pragma once

// Démarrage commun des applications VinX (Paramètres, Store, Bienvenue).

#include <QCommandLineParser>
#include <QDir>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>

inline int vinxAppMain(int argc, char *argv[], const char *appName, const char *desktopId, const char *qmlUrl,
                       const QList<QCommandLineOption> &extraOptions = {}, const QStringList &stringProperties = {})
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QString::fromLatin1(appName));
    app.setApplicationVersion(QStringLiteral(VINX_VERSION));
    app.setDesktopFileName(QString::fromLatin1(desktopId));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("vinx-logo")));

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption shot(QStringLiteral("screenshot"), QStringLiteral("Enregistre une capture puis quitte."), QStringLiteral("fichier"));
    parser.addOption(shot);
    for (const auto &o : extraOptions)
        parser.addOption(o);
    parser.process(app);

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
    if (QDir(QStringLiteral(VINX_BUILD_QML_DIR)).exists())
        engine.addImportPath(QStringLiteral(VINX_BUILD_QML_DIR));
    QVariantMap props;
    for (int i = 0; i < extraOptions.size() && i < stringProperties.size(); ++i)
        props.insert(stringProperties.at(i), parser.value(extraOptions.at(i)));
    engine.setInitialProperties(props);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl(QString::fromLatin1(qmlUrl)));

    if (parser.isSet(shot) && !engine.rootObjects().isEmpty()) {
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
        const QString file = parser.value(shot);
        QTimer::singleShot(900, &app, [window, file] { QCoreApplication::exit(window && window->grabWindow().save(file) ? 0 : 2); });
    }
    return app.exec();
}
