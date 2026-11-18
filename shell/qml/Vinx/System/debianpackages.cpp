#include "debianpackages.h"
#include "syscmd.h"
#include "sysparse.h"

#include <QUrl>

DebianPackages::DebianPackages(QObject *parent)
    : QObject(parent)
    , m_available(hasCommand(QStringLiteral("apt-cache")))
{
}

void DebianPackages::search(const QString &query, bool tools)
{
    const int serial = ++m_serial;
    const QString q = query.trimmed();
    if (!m_available || q.size() < 2) {
        m_results.clear();
        m_searching = false;
        Q_EMIT resultsChanged();
        return;
    }
    m_searching = true;
    Q_EMIT resultsChanged();
    runCommand(this, QStringLiteral("appstreamcli"), {QStringLiteral("search"), q}, [=](bool, const QString &out, const QString &) {
        if (serial != m_serial)
            return;
        QVariantList list = parseAppstreamSearch(out);
        for (QVariant &v : list) {   // logo des logiciels non installés (cache AppStream)
            QVariantMap m = v.toMap();
            const QString path = resolveAppstreamIcon(m.value(QStringLiteral("iconCached")).toString(), appstreamIconRoots());
            if (!path.isEmpty())
                m.insert(QStringLiteral("iconUrl"), QUrl::fromLocalFile(path).toString());
            v = m;
        }
        if (!tools) {
            markInstalled(list.mid(0, 40), serial);
            return;
        }
        runCommand(this, QStringLiteral("apt-cache"), {QStringLiteral("search"), QStringLiteral("--names-only"), q}, [=](bool, const QString &aptOut, const QString &) {
            if (serial != m_serial)
                return;
            QVariantList all = list;
            QStringList have;
            for (const QVariant &v : list)
                have << v.toMap().value(QStringLiteral("package")).toString();
            for (const QVariant &v : parseAptSearch(aptOut))
                if (!have.contains(v.toMap().value(QStringLiteral("package")).toString()))
                    all.append(v);
            markInstalled(all.mid(0, 60), serial);
        });
    }, 20000);
}

void DebianPackages::markInstalled(QVariantList list, int serial)
{
    QStringList pkgs;
    for (const QVariant &v : list)
        pkgs << v.toMap().value(QStringLiteral("package")).toString();
    if (pkgs.isEmpty()) {
        m_results.clear();
        m_searching = false;
        Q_EMIT resultsChanged();
        return;
    }
    runCommand(this, QStringLiteral("dpkg-query"), QStringList{QStringLiteral("-W"), QStringLiteral("-f=${Package} ${db:Status-Abbrev}\\n")} + pkgs,
               [=](bool, const QString &out, const QString &) mutable {
                   if (serial != m_serial)
                       return;
                   QStringList installed;
                   for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts))
                       if (line.section(QLatin1Char(' '), 1, 1).startsWith(QLatin1String("ii")))
                           installed << line.section(QLatin1Char(' '), 0, 0);
                   for (QVariant &v : list) {
                       QVariantMap m = v.toMap();
                       m.insert(QStringLiteral("installed"), installed.contains(m.value(QStringLiteral("package")).toString()));
                       v = m;
                   }
                   m_results = list;
                   m_searching = false;
                   Q_EMIT resultsChanged();
               });
}

void DebianPackages::details(const QString &package)
{
    runCommand(this, QStringLiteral("apt-cache"), {QStringLiteral("show"), package}, [=](bool, const QString &out, const QString &) {
        Q_EMIT detailsReady(package, parseAptShow(out));
    });
}

void DebianPackages::runPkcon(const QStringList &args, const QString &task, const QString &okMsg, const QString &failMsg)
{
    if (m_proc)
        return;
    m_proc = new QProcess(this);
    m_proc->setProcessChannelMode(QProcess::MergedChannels);
    m_task = task;
    m_progress = 0;
    connect(m_proc, &QProcess::readyRead, this, [this] {
        while (m_proc->canReadLine()) {
            const int p = parseProgressLine(QString::fromUtf8(m_proc->readLine()));
            if (p >= 0 && p != m_progress) { m_progress = p; Q_EMIT busyChanged(); }
        }
    });
    connect(m_proc, &QProcess::finished, this, [=](int code, QProcess::ExitStatus st) {
        const bool ok = st == QProcess::NormalExit && code == 0;
        m_proc->deleteLater();
        m_proc = nullptr;
        m_progress = -1;
        Q_EMIT busyChanged();
        Q_EMIT finished(ok, ok ? okMsg : failMsg);
        // Rafraîchit l'état « installé » des résultats affichés.
        QVariantList list = m_results;
        markInstalled(list, m_serial);
        refreshCatalogInstalled();
    });
    m_proc->start(QStringLiteral("pkcon"), QStringList{QStringLiteral("--plain"), QStringLiteral("-y")} + args);
    Q_EMIT busyChanged();
}

void DebianPackages::install(const QString &package, const QString &label)
{
    runPkcon({QStringLiteral("install"), package}, tr("Installation de %1").arg(label), tr("%1 est installé.").arg(label),
             tr("L'installation de %1 a échoué.").arg(label));
}

void DebianPackages::remove(const QString &package, const QString &label)
{
    runPkcon({QStringLiteral("remove"), package}, tr("Suppression de %1").arg(label), tr("%1 a été supprimé.").arg(label),
             tr("La suppression de %1 a échoué.").arg(label));
}

bool DebianPackages::launch(const QString &desktopId) const
{
    QString id = desktopId;
    if (id.endsWith(QLatin1String(".desktop")))
        id.chop(8);
    return QProcess::startDetached(QStringLiteral("gtk-launch"), {id}) || QProcess::startDetached(QStringLiteral("kioclient"), {QStringLiteral("exec"), id + QStringLiteral(".desktop")});
}

void DebianPackages::lookup(const QStringList &packages)
{
    if (!m_available || !hasCommand(QStringLiteral("appstreamcli")))
        return;
    const bool idle = m_lookupQueue.isEmpty();
    for (const QString &p : packages)
        if (!p.isEmpty() && !m_catalog.contains(p) && !m_lookupQueue.contains(p))
            m_lookupQueue << p;
    Q_EMIT catalogChanged();
    if (idle && !m_lookupQueue.isEmpty())
        lookupNext();
}

void DebianPackages::lookupNext()
{
    if (m_lookupQueue.isEmpty()) {
        refreshCatalogInstalled();
        return;
    }
    const QString pkg = m_lookupQueue.constFirst();
    runCommand(this, QStringLiteral("appstreamcli"), {QStringLiteral("search"), pkg}, [=](bool, const QString &out, const QString &) {
        m_lookupQueue.removeAll(pkg);
        for (const QVariant &v : parseAppstreamSearch(out)) {
            QVariantMap m = v.toMap();
            if (m.value(QStringLiteral("package")).toString() != pkg)
                continue;
            const QString path = resolveAppstreamIcon(m.value(QStringLiteral("iconCached")).toString(), appstreamIconRoots());
            if (!path.isEmpty())
                m.insert(QStringLiteral("iconUrl"), QUrl::fromLocalFile(path).toString());
            m.insert(QStringLiteral("installed"), false);
            m_catalog.insert(pkg, m);
            break;
        }
        Q_EMIT catalogChanged();
        lookupNext();
    }, 20000);
}

void DebianPackages::refreshCatalogInstalled()
{
    const QStringList pkgs = m_catalog.keys();
    if (pkgs.isEmpty())
        return;
    runCommand(this, QStringLiteral("dpkg-query"), QStringList{QStringLiteral("-W"), QStringLiteral("-f=${Package} ${db:Status-Abbrev}\\n")} + pkgs,
               [this](bool, const QString &out, const QString &) {
                   QStringList installed;
                   for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts))
                       if (line.section(QLatin1Char(' '), 1, 1).startsWith(QLatin1String("ii")))
                           installed << line.section(QLatin1Char(' '), 0, 0);
                   for (auto it = m_catalog.begin(); it != m_catalog.end(); ++it) {
                       QVariantMap m = it.value().toMap();
                       m.insert(QStringLiteral("installed"), installed.contains(it.key()));
                       it.value() = m;
                   }
                   Q_EMIT catalogChanged();
               });
}
