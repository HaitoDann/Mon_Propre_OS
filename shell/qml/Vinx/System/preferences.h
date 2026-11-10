#pragma once

#include <QFileSystemWatcher>
#include <QObject>
#include <QSettings>
#include <QVariant>
#include <QtQml/qqmlregistration.h>

// Préférences partagées par le shell et les applications VinX (~/.config/vinx/shell.ini).
// Une modification faite par un autre processus (ex. Paramètres) émet changed().
class Preferences : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(int revision READ revision NOTIFY changed)

public:
    explicit Preferences(QObject *parent = nullptr);
    Q_INVOKABLE QVariant value(const QString &key, const QVariant &defaultValue = {}) const;
    Q_INVOKABLE void setValue(const QString &key, const QVariant &value);
    // Incrémenté à chaque changement : permet des liaisons QML réactives (Preferences.revision).
    int revision() const { return m_revision; }

Q_SIGNALS:
    void changed();

private:
    void watch();
    void reload();

    QSettings m_settings;
    QFileSystemWatcher m_watcher;
    int m_revision = 0;
};
