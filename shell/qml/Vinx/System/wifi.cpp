#include "wifi.h"
#include "syscmd.h"
#include "sysparse.h"

Wifi::Wifi(QObject *parent)
    : QObject(parent)
    , m_available(hasCommand(QStringLiteral("nmcli")))
{
    refresh(false);
}

void Wifi::setEnabled(bool on)
{
    if (!m_available)
        return;
    m_enabled = on;
    Q_EMIT changed();
    runCommand(this, QStringLiteral("nmcli"), {QStringLiteral("radio"), QStringLiteral("wifi"), on ? QStringLiteral("on") : QStringLiteral("off")},
               [this](bool, const QString &, const QString &) { refresh(true); });
}

void Wifi::refresh(bool rescan)
{
    if (!m_available || m_scanning)
        return;
    m_scanning = true;
    Q_EMIT changed();
    runCommand(this, QStringLiteral("nmcli"), {QStringLiteral("radio"), QStringLiteral("wifi")},
               [this](bool, const QString &out, const QString &) { m_enabled = out.trimmed() != QLatin1String("disabled"); });
    runCommand(this, QStringLiteral("nmcli"), {QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("NAME,TYPE"), QStringLiteral("connection"), QStringLiteral("show")},
               [this](bool, const QString &out, const QString &) { m_known = parseNmcliKnownWifi(out); merge(); });
    runCommand(this, QStringLiteral("nmcli"),
               {QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("IN-USE,SSID,SIGNAL,SECURITY"), QStringLiteral("device"), QStringLiteral("wifi"),
                QStringLiteral("list"), QStringLiteral("--rescan"), rescan ? QStringLiteral("yes") : QStringLiteral("auto")},
               [this](bool, const QString &out, const QString &) {
                   m_scan = parseNmcliWifi(out);
                   m_scanning = false;
                   merge();
               }, 30000);
}

void Wifi::merge()
{
    QVariantList out;
    for (const QVariant &v : std::as_const(m_scan)) {
        QVariantMap n = v.toMap();
        n.insert(QStringLiteral("known"), m_known.contains(n.value(QStringLiteral("ssid")).toString()));
        out.append(n);
    }
    m_networks = out;
    Q_EMIT changed();
}

static QString friendlyError(const QString &err)
{
    if (err.contains(QLatin1String("Secrets were required")) || err.contains(QLatin1String("802-11-wireless-security.psk")))
        return QObject::tr("Mot de passe incorrect.");
    if (err.contains(QLatin1String("No network with SSID")))
        return QObject::tr("Réseau introuvable.");
    if (err.contains(QLatin1String("timed out")) || err.contains(QLatin1String("Timeout")))
        return QObject::tr("Le réseau ne répond pas.");
    return QObject::tr("Connexion impossible.");
}

void Wifi::connectTo(const QString &ssid, const QString &password, bool hidden)
{
    if (!m_available || ssid.isEmpty() || busy())
        return;
    m_pending = ssid;
    Q_EMIT changed();
    QStringList args;
    if (password.isEmpty() && m_known.contains(ssid))
        args = {QStringLiteral("connection"), QStringLiteral("up"), QStringLiteral("id"), ssid};
    else {
        args = {QStringLiteral("device"), QStringLiteral("wifi"), QStringLiteral("connect"), ssid};
        if (!password.isEmpty())
            args << QStringLiteral("password") << password;
        if (hidden)
            args << QStringLiteral("hidden") << QStringLiteral("yes");
    }
    runCommand(this, QStringLiteral("nmcli"), args, [this, ssid, password](bool ok, const QString &, const QString &err) {
        m_pending.clear();
        // Échec avec un nouveau mot de passe : ne pas garder un profil inutilisable.
        if (!ok && !password.isEmpty() && !m_known.contains(ssid))
            runCommand(this, QStringLiteral("nmcli"), {QStringLiteral("connection"), QStringLiteral("delete"), QStringLiteral("id"), ssid},
                       [](bool, const QString &, const QString &) {});
        Q_EMIT finished(ok, ok ? tr("Connecté à « %1 ».").arg(ssid) : friendlyError(err));
        refresh(false);
    }, 90000);
}

void Wifi::disconnectCurrent()
{
    runCommand(this, QStringLiteral("nmcli"), {QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("DEVICE,TYPE,STATE"), QStringLiteral("device")},
               [this](bool, const QString &out, const QString &) {
                   for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
                       const QStringList f = splitNmcliTerse(line);
                       if (f.size() >= 3 && f[1] == QLatin1String("wifi") && f[2] == QLatin1String("connected"))
                           runCommand(this, QStringLiteral("nmcli"), {QStringLiteral("device"), QStringLiteral("disconnect"), f[0]},
                                      [this](bool, const QString &, const QString &) { refresh(false); });
                   }
               });
}

void Wifi::forget(const QString &ssid)
{
    runCommand(this, QStringLiteral("nmcli"), {QStringLiteral("connection"), QStringLiteral("delete"), QStringLiteral("id"), ssid},
               [this, ssid](bool ok, const QString &, const QString &) {
                   Q_EMIT finished(ok, ok ? tr("« %1 » a été oublié.").arg(ssid) : tr("Impossible d'oublier ce réseau."));
                   refresh(false);
               });
}
