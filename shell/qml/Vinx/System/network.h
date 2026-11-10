#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

// État réseau via NetworkManager : connexion principale, Wi-Fi activé ou non.
class Network : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(bool connected READ connected NOTIFY changed)
    Q_PROPERTY(bool wireless READ wireless NOTIFY changed)
    Q_PROPERTY(bool wirelessEnabled READ wirelessEnabled WRITE setWirelessEnabled NOTIFY changed)
    Q_PROPERTY(QString connectionName READ connectionName NOTIFY changed)

public:
    explicit Network(QObject *parent = nullptr);
    bool available() const { return m_available; }
    bool connected() const { return m_connected; }
    bool wireless() const { return m_wireless; }
    bool wirelessEnabled() const { return m_wirelessEnabled; }
    QString connectionName() const { return m_connectionName; }
    void setWirelessEnabled(bool enabled);

Q_SIGNALS:
    void changed();

private Q_SLOTS:
    void refresh();

private:
    bool m_available = false;
    bool m_connected = false;
    bool m_wireless = false;
    bool m_wirelessEnabled = false;
    QString m_connectionName;
};
