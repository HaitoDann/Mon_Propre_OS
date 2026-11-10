#pragma once

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDBusVariant>
#include <QVariantMap>

// Petites aides D-Bus communes aux services système.
namespace VinxDBus {

inline QVariantMap getAll(const QDBusConnection &bus, const QString &service, const QString &path, const QString &iface)
{
    QDBusInterface props(service, path, QStringLiteral("org.freedesktop.DBus.Properties"), bus);
    if (!props.isValid())
        return {};
    const QDBusReply<QVariantMap> reply = props.call(QStringLiteral("GetAll"), iface);
    return reply.isValid() ? reply.value() : QVariantMap();
}

inline QVariant get(const QDBusConnection &bus, const QString &service, const QString &path, const QString &iface, const QString &name)
{
    QDBusInterface props(service, path, QStringLiteral("org.freedesktop.DBus.Properties"), bus);
    if (!props.isValid())
        return {};
    const QDBusReply<QDBusVariant> reply = props.call(QStringLiteral("Get"), iface, name);
    return reply.isValid() ? reply.value().variant() : QVariant();
}

inline bool set(const QDBusConnection &bus, const QString &service, const QString &path, const QString &iface, const QString &name, const QVariant &value)
{
    QDBusInterface props(service, path, QStringLiteral("org.freedesktop.DBus.Properties"), bus);
    if (!props.isValid())
        return false;
    return props.call(QStringLiteral("Set"), iface, name, QVariant::fromValue(QDBusVariant(value))).type() != QDBusMessage::ErrorMessage;
}

} // namespace VinxDBus
