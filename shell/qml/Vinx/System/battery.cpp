#include "battery.h"
#include "dbusutil.h"

namespace {
const QString kService = QStringLiteral("org.freedesktop.UPower");
const QString kPath = QStringLiteral("/org/freedesktop/UPower/devices/DisplayDevice");
const QString kIface = QStringLiteral("org.freedesktop.UPower.Device");
}

Battery::Battery(QObject *parent)
    : QObject(parent)
{
    QDBusConnection::systemBus().connect(kService, kPath, QStringLiteral("org.freedesktop.DBus.Properties"),
                                         QStringLiteral("PropertiesChanged"), this, SLOT(refresh()));
    refresh();
}

void Battery::refresh()
{
    const QVariantMap p = VinxDBus::getAll(QDBusConnection::systemBus(), kService, kPath, kIface);
    // Type 2 = batterie ; State : 1 en charge, 4 pleine, 5 en attente de charge.
    m_present = p.value(QStringLiteral("IsPresent")).toBool() && p.value(QStringLiteral("Type")).toUInt() == 2;
    m_percentage = qRound(p.value(QStringLiteral("Percentage")).toDouble());
    const uint state = p.value(QStringLiteral("State")).toUInt();
    m_charging = state == 1 || state == 4 || state == 5;
    Q_EMIT changed();
}
