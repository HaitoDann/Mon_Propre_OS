#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Réseaux Wi-Fi (NetworkManager via nmcli) : liste, connexion, réseaux connus, oubli.
class Wifi : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY changed)
    Q_PROPERTY(bool scanning READ scanning NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(QVariantList networks READ networks NOTIFY changed)   // [{ ssid, signal, secure, active, known }]
    Q_PROPERTY(QString pending READ pending NOTIFY changed)          // réseau en cours de connexion

public:
    explicit Wifi(QObject *parent = nullptr);
    bool available() const { return m_available; }
    bool enabled() const { return m_enabled; }
    void setEnabled(bool on);
    bool scanning() const { return m_scanning; }
    bool busy() const { return !m_pending.isEmpty(); }
    QVariantList networks() const { return m_networks; }
    QString pending() const { return m_pending; }

    Q_INVOKABLE void refresh(bool rescan = false);
    // Mot de passe vide : réseau ouvert ou déjà connu. hidden : réseau masqué.
    Q_INVOKABLE void connectTo(const QString &ssid, const QString &password = {}, bool hidden = false);
    Q_INVOKABLE void disconnectCurrent();
    Q_INVOKABLE void forget(const QString &ssid);

Q_SIGNALS:
    void changed();
    void finished(bool success, const QString &message);

private:
    void merge();
    bool m_available = false;
    bool m_enabled = true;
    bool m_scanning = false;
    QString m_pending;
    QVariantList m_scan, m_networks;
    QStringList m_known;
};
