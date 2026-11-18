#pragma once

#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Paramètres → Réseau (ADR 0030) : VPN (import WireGuard / OpenVPN, connexion) et adresse IP fixe
// de la connexion active, via nmcli — sans le module réseau de KDE.
class NetConfig : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QVariantList vpns READ vpns NOTIFY changed)                 // [{ name, kind, active }]
    Q_PROPERTY(QString activeConnection READ activeConnection NOTIFY changed)
    Q_PROPERTY(QVariantMap ipv4 READ ipv4 NOTIFY changed)                  // { manual, address, prefix, gateway, dns }
public:
    explicit NetConfig(QObject *parent = nullptr);
    QVariantList vpns() const { return m_vpns; }
    QString activeConnection() const { return m_active; }
    QVariantMap ipv4() const { return m_ipv4; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void importVpn(const QString &fileUrl);
    Q_INVOKABLE void setVpnActive(const QString &name, bool active);
    Q_INVOKABLE void removeVpn(const QString &name);
    Q_INVOKABLE void setAutomaticIp();
    Q_INVOKABLE void setManualIp(const QString &address, int prefix, const QString &gateway, const QString &dns);

Q_SIGNALS:
    void changed();
    void finished(bool success, const QString &message);

private:
    void nmcli(const QStringList &args, const QString &ok, const QString &fail, bool reapply = false);
    QVariantList m_vpns;
    QString m_active;
    QVariantMap m_ipv4;
};
