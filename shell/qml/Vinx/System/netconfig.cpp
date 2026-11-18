#include "netconfig.h"
#include "syscmd.h"
#include "sysparse.h"

#include <QUrl>

NetConfig::NetConfig(QObject *parent)
    : QObject(parent)
{
}

void NetConfig::refresh()
{
    runCommand(this, QStringLiteral("nmcli"), {QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("NAME,TYPE,ACTIVE,DEVICE"),
                                               QStringLiteral("connection"), QStringLiteral("show")},
               [this](bool, const QString &out, const QString &) {
                   m_vpns = parseNmcliVpns(out);
                   // Connexion principale active (Wi-Fi ou filaire) : celle dont on règle l'adresse IP.
                   m_active.clear();
                   for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
                       const QStringList f = splitNmcliTerse(line);
                       if (f.size() >= 3 && f.at(2) == QLatin1String("yes")
                           && (f.at(1) == QLatin1String("802-11-wireless") || f.at(1) == QLatin1String("802-3-ethernet"))) {
                           m_active = f.at(0);
                           break;
                       }
                   }
                   Q_EMIT changed();
                   if (m_active.isEmpty())
                       return;
                   runCommand(this, QStringLiteral("nmcli"), {QStringLiteral("-t"), QStringLiteral("-f"),
                                                              QStringLiteral("ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns"),
                                                              QStringLiteral("connection"), QStringLiteral("show"), m_active},
                              [this](bool, const QString &ipOut, const QString &) {
                                  m_ipv4 = parseNmcliIpv4(ipOut);
                                  Q_EMIT changed();
                              });
               });
}

void NetConfig::nmcli(const QStringList &args, const QString &ok, const QString &fail, bool reapply)
{
    runCommand(this, QStringLiteral("nmcli"), args, [=](bool success, const QString &, const QString &err) {
        if (success && reapply && !m_active.isEmpty()) {
            // La connexion est relancée pour appliquer la nouvelle adresse.
            runCommand(this, QStringLiteral("nmcli"), {QStringLiteral("connection"), QStringLiteral("up"), m_active},
                       [=](bool upOk, const QString &, const QString &) {
                           Q_EMIT finished(upOk, upOk ? ok : fail);
                           refresh();
                       }, 30000);
            return;
        }
        Q_EMIT finished(success, success ? ok : fail + (err.trimmed().isEmpty() ? QString() : QStringLiteral(" (") + err.trimmed() + QLatin1Char(')')));
        refresh();
    }, 30000);
}

void NetConfig::importVpn(const QString &fileUrl)
{
    const QString path = QUrl(fileUrl).isLocalFile() ? QUrl(fileUrl).toLocalFile() : fileUrl;
    const QString type = path.endsWith(QLatin1String(".conf")) ? QStringLiteral("wireguard") : QStringLiteral("openvpn");
    nmcli({QStringLiteral("connection"), QStringLiteral("import"), QStringLiteral("type"), type, QStringLiteral("file"), path},
          tr("VPN importé."), type == QLatin1String("openvpn")
              ? tr("Import impossible : le fichier n'est pas reconnu, ou le module OpenVPN (network-manager-openvpn) n'est pas installé.")
              : tr("Import impossible : fichier WireGuard non reconnu."));
}

void NetConfig::setVpnActive(const QString &name, bool active)
{
    nmcli({QStringLiteral("connection"), active ? QStringLiteral("up") : QStringLiteral("down"), name},
          active ? tr("Connecté à %1.").arg(name) : tr("Déconnecté de %1.").arg(name),
          tr("Impossible de changer l'état de %1.").arg(name));
}

void NetConfig::removeVpn(const QString &name)
{
    nmcli({QStringLiteral("connection"), QStringLiteral("delete"), name}, tr("VPN supprimé."), tr("Impossible de supprimer le VPN."));
}

void NetConfig::setAutomaticIp()
{
    if (m_active.isEmpty())
        return;
    nmcli({QStringLiteral("connection"), QStringLiteral("modify"), m_active, QStringLiteral("ipv4.method"), QStringLiteral("auto"),
           QStringLiteral("ipv4.addresses"), QString(), QStringLiteral("ipv4.gateway"), QString(), QStringLiteral("ipv4.dns"), QString()},
          tr("Adresse automatique rétablie."), tr("Impossible de modifier la connexion."), true);
}

void NetConfig::setManualIp(const QString &address, int prefix, const QString &gateway, const QString &dns)
{
    if (m_active.isEmpty())
        return;
    nmcli({QStringLiteral("connection"), QStringLiteral("modify"), m_active, QStringLiteral("ipv4.method"), QStringLiteral("manual"),
           QStringLiteral("ipv4.addresses"), address + QLatin1Char('/') + QString::number(prefix),
           QStringLiteral("ipv4.gateway"), gateway, QStringLiteral("ipv4.dns"), dns},
          tr("Adresse fixe enregistrée."), tr("Adresse refusée : vérifiez les valeurs."), true);
}
