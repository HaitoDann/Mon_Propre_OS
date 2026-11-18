// vinx-polkit-agent : agent d'authentification polkit de la session VinX (ADR 0028).
#include "agent.h"

#include <PolkitQt1/Subject>

#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <unistd.h>

int main(int argc, char **argv)
{
    // Session VinX seulement : ailleurs, l'agent de KDE (ou d'un autre bureau) s'en charge.
    if (qEnvironmentVariableIntValue("VINX_SESSION") != 1 && qEnvironmentVariableIntValue("VINX_POLKIT_FORCE") != 1)
        return 0;
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("vinx-polkit-agent"));
    app.setQuitOnLastWindowClosed(false);

    Agent agent;
    PolkitQt1::UnixSessionSubject session(getpid());
    if (!agent.registerListener(session, QStringLiteral("/org/vinx/PolicyKit1/AuthenticationAgent"))) {
        qCritical("vinx-polkit-agent : impossible de s'enregistrer auprès de polkit (un autre agent est actif ?)");
        return 1;
    }

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
    if (QDir(QStringLiteral(VINX_BUILD_QML_DIR)).exists())
        engine.addImportPath(QStringLiteral(VINX_BUILD_QML_DIR));
    engine.rootContext()->setContextProperty(QStringLiteral("agent"), &agent);
    engine.load(QUrl(QStringLiteral("qrc:/vinx-polkit-agent/AuthDialog.qml")));
    return app.exec();
}
