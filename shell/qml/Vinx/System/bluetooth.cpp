#include "bluetooth.h"
#include "dbusutil.h"

namespace {
const QString kService = QStringLiteral("org.bluez");
const QString kPath = QStringLiteral("/org/bluez/hci0");
const QString kIface = QStringLiteral("org.bluez.Adapter1");
}

Bluetooth::Bluetooth(QObject *parent)
    : QObject(parent)
{
    QDBusConnection::systemBus().connect(kService, kPath, QStringLiteral("org.freedesktop.DBus.Properties"),
                                         QStringLiteral("PropertiesChanged"), this, SLOT(refresh()));
    refresh();
}

void Bluetooth::refresh()
{
    const QVariantMap p = VinxDBus::getAll(QDBusConnection::systemBus(), kService, kPath, kIface);
    m_available = !p.isEmpty();
    m_powered = p.value(QStringLiteral("Powered")).toBool();
    Q_EMIT changed();
}

void Bluetooth::setPowered(bool on)
{
    VinxDBus::set(QDBusConnection::systemBus(), kService, kPath, kIface, QStringLiteral("Powered"), on);
    refresh();
}
