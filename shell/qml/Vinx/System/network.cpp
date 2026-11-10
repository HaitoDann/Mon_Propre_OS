#include "network.h"
#include "dbusutil.h"

#include <QDBusObjectPath>

namespace {
const QString kService = QStringLiteral("org.freedesktop.NetworkManager");
const QString kPath = QStringLiteral("/org/freedesktop/NetworkManager");
const QString kIface = QStringLiteral("org.freedesktop.NetworkManager");
}

Network::Network(QObject *parent)
    : QObject(parent)
{
    QDBusConnection::systemBus().connect(kService, kPath, QStringLiteral("org.freedesktop.DBus.Properties"),
                                         QStringLiteral("PropertiesChanged"), this, SLOT(refresh()));
    refresh();
}

void Network::refresh()
{
    const auto bus = QDBusConnection::systemBus();
    const QVariantMap p = VinxDBus::getAll(bus, kService, kPath, kIface);
    m_available = !p.isEmpty();
    // NMState : 70 = connecté (global), 60 = site, 50 = local.
    m_connected = p.value(QStringLiteral("State")).toUInt() >= 50;
    m_wirelessEnabled = p.value(QStringLiteral("WirelessEnabled")).toBool();
    m_connectionName.clear();
    m_wireless = false;

    const QString primary = qvariant_cast<QDBusObjectPath>(p.value(QStringLiteral("PrimaryConnection"))).path();
    if (m_connected && !primary.isEmpty() && primary != QLatin1String("/")) {
        const QVariantMap c = VinxDBus::getAll(bus, kService, primary, QStringLiteral("org.freedesktop.NetworkManager.Connection.Active"));
        m_connectionName = c.value(QStringLiteral("Id")).toString();
        m_wireless = c.value(QStringLiteral("Type")).toString() == QLatin1String("802-11-wireless");
    }
    Q_EMIT changed();
}

void Network::setWirelessEnabled(bool enabled)
{
    VinxDBus::set(QDBusConnection::systemBus(), kService, kPath, kIface, QStringLiteral("WirelessEnabled"), enabled);
    refresh();
}
