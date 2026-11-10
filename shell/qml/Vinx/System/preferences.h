#pragma once

#include <QObject>
#include <QSettings>
#include <QVariant>
#include <QtQml/qqmlregistration.h>

// Préférences du shell (~/.config/vinx/shell.conf).
class Preferences : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Preferences(QObject *parent = nullptr);
    Q_INVOKABLE QVariant value(const QString &key, const QVariant &defaultValue = {}) const;
    Q_INVOKABLE void setValue(const QString &key, const QVariant &value);

private:
    QSettings m_settings;
};
