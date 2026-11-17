#include "diagnostics.h"
#include "diagparse.h"
#include "syscmd.h"

#include <QCoreApplication>

Diagnostics::Diagnostics(QObject *parent)
    : QObject(parent)
{
}

void Diagnostics::run(bool full)
{
    if (running())
        return;
    m_log.clear();
    m_extra.clear();
    m_pending = 4;
    Q_EMIT changed();

    auto collect = [this](bool, const QString &out, const QString &) { m_log += out + QLatin1Char('\n'); done(); };
    if (full) {
        runCommand(this, QStringLiteral("pkexec"), {vinxAdmin(), QStringLiteral("journal")}, [this](bool ok, const QString &out, const QString &) {
            if (ok)
                m_limited = false;
            m_log += out + QLatin1Char('\n');
            done();
        }, 0);
    } else {
        runCommand(this, QStringLiteral("journalctl"), {QStringLiteral("-b"), QStringLiteral("-p"), QStringLiteral("4"), QStringLiteral("-n"), QStringLiteral("3000"),
                                                        QStringLiteral("-o"), QStringLiteral("short"), QStringLiteral("--no-pager")},
                   [this](bool, const QString &out, const QString &err) {
                       // Sans le groupe « adm » ou « systemd-journal », seul le journal de l'utilisateur est lisible.
                       m_limited = (err + out).contains(QLatin1String("not seeing messages from other users"));
                       m_log += out + QLatin1Char('\n');
                       done();
                   });
    }
    runCommand(this, QStringLiteral("journalctl"), {QStringLiteral("--user"), QStringLiteral("-b"), QStringLiteral("-n"), QStringLiteral("1500"),
                                                    QStringLiteral("-o"), QStringLiteral("short"), QStringLiteral("--no-pager")}, collect);

    runCommand(this, QStringLiteral("df"), {QStringLiteral("-P"), QStringLiteral("/")}, [this](bool, const QString &out, const QString &) {
        const int used = parseDfUsage(out);
        if (used >= 90)
            m_extra.append(QVariantMap{{QStringLiteral("id"), QStringLiteral("disk-full")}, {QStringLiteral("severity"), used >= 97 ? 2 : 1},
                                       {QStringLiteral("title"), tr("Le disque est presque plein (%1 %)").arg(used)},
                                       {QStringLiteral("advice"), tr("Videz la corbeille, supprimez les téléchargements inutiles ou les applications que vous n'utilisez plus.")},
                                       {QStringLiteral("action"), QStringLiteral("run:vinx-files")}, {QStringLiteral("actionLabel"), tr("Ouvrir Fichiers")},
                                       {QStringLiteral("count"), 1}, {QStringLiteral("sample"), out.trimmed().section(QLatin1Char('\n'), -1)}});
        done();
    });
    runCommand(this, QStringLiteral("nmcli"), {QStringLiteral("networking"), QStringLiteral("connectivity"), QStringLiteral("check")},
               [this](bool ok, const QString &out, const QString &) {
                   const QString c = out.trimmed();
                   if (ok && (c == QLatin1String("none") || c == QLatin1String("limited") || c == QLatin1String("portal")))
                       m_extra.append(QVariantMap{{QStringLiteral("id"), QStringLiteral("offline")}, {QStringLiteral("severity"), 2},
                                                  {QStringLiteral("title"), c == QLatin1String("portal") ? tr("Une page de connexion au réseau vous attend")
                                                                                                         : tr("Pas d'accès à Internet")},
                                                  {QStringLiteral("advice"), c == QLatin1String("portal")
                                                       ? tr("Ce réseau (hôtel, gare…) demande de vous identifier : ouvrez Firefox pour afficher sa page.")
                                                       : tr("Vérifiez que vous êtes connecté à un réseau et que la box a accès à Internet (redémarrez-la si besoin).")},
                                                  {QStringLiteral("action"), c == QLatin1String("portal") ? QStringLiteral("run:firefox-esr") : QStringLiteral("page:network")},
                                                  {QStringLiteral("actionLabel"), c == QLatin1String("portal") ? tr("Ouvrir Firefox") : tr("Ouvrir Réseau")},
                                                  {QStringLiteral("count"), 1}, {QStringLiteral("sample"), QStringLiteral("connectivity: ") + c}});
                   done();
               }, 15000);
}

void Diagnostics::done()
{
    if (--m_pending > 0)
        return;
    QVariantList list = m_extra;
    list += diagnoseLog(m_log, [](const char *s) { return QCoreApplication::translate("Diag", s); });
    m_issues = list;
    // Détail technique : les dernières lignes d'avertissement et d'erreur.
    QStringList lines = m_log.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    m_details = lines.mid(qMax(0, int(lines.size()) - 80)).join(QLatin1Char('\n'));
    m_lastRun = QDateTime::currentDateTime();
    m_pending = 0;
    Q_EMIT changed();
}
