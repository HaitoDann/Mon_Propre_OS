#include "shellservice.h"

#include <QDBusConnection>

ShellService::ShellService(QObject *parent)
    : QObject(parent)
{
    if (qEnvironmentVariableIntValue("VINX_SHELL_PROCESS") != 1)
        return;
    auto bus = QDBusConnection::sessionBus();
    m_registered = bus.isConnected()
        && bus.registerObject(QStringLiteral("/Shell"), this, QDBusConnection::ExportScriptableSlots)
        && bus.registerService(QStringLiteral("org.vinx.Shell"));
}
