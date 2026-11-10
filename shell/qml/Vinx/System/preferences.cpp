#include "preferences.h"

Preferences::Preferences(QObject *parent)
    : QObject(parent)
    , m_settings(QSettings::IniFormat, QSettings::UserScope, QStringLiteral("vinx"), QStringLiteral("shell"))
{
}

QVariant Preferences::value(const QString &key, const QVariant &defaultValue) const
{
    return m_settings.value(key, defaultValue);
}

void Preferences::setValue(const QString &key, const QVariant &value)
{
    m_settings.setValue(key, value);
}
