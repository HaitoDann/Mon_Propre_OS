#include "kdeprompts.h"

#include <QDBusConnection>

DesktopPrompts::DesktopPrompts(QObject *parent)
    : QObject(parent)
{
    if (qEnvironmentVariableIntValue("VINX_SHELL_PROCESS") != 1)
        return;
    auto bus = QDBusConnection::sessionBus();
    if (!bus.isConnected())
        return;
    m_osd = bus.registerObject(QStringLiteral("/org/kde/osdService"), new OsdAdaptor(this), QDBusConnection::ExportAllSlots)
        && bus.registerService(QStringLiteral("org.kde.osdService"));
    m_logout = bus.registerObject(QStringLiteral("/LogoutPrompt"), new LogoutAdaptor(this), QDBusConnection::ExportAllSlots)
        && bus.registerService(QStringLiteral("org.kde.LogoutPrompt"));
}

void OsdAdaptor::volumeChanged(int percent, int maximumPercent)
{
    // Au-delà de 100 % (amplification) : la jauge reste proportionnelle au maximum autorisé.
    const int shown = maximumPercent > 100 ? percent * 100 / maximumPercent : percent;
    emitOsd(QStringLiteral("volume"), percent == 0 ? QStringLiteral("volume-off") : QStringLiteral("volume"), shown,
            QStringLiteral("%1 %").arg(percent));
}

void OsdAdaptor::powerManagementInhibitedChanged(bool inhibited)
{
    emitOsd(QStringLiteral("text"), QStringLiteral("bolt"), -1,
            inhibited ? tr("Mise en veille désactivée") : tr("Mise en veille réactivée"));
}

void OsdAdaptor::powerProfileChanged(const QString &profile)
{
    const QString name = profile == QLatin1String("power-saver") ? tr("Économie d'énergie")
        : profile == QLatin1String("performance") ? tr("Performances") : tr("Équilibré");
    emitOsd(QStringLiteral("text"), QStringLiteral("bolt"), -1, tr("Mode d'énergie : %1").arg(name));
}
