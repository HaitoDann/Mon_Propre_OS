#include "flatpak.h"
#include <QUrl>
#include <QFileInfo>
#include <QDir>
#include "updateparse.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QRegularExpression>
#include <QStandardPaths>

namespace {
const QString kFlathub = QStringLiteral("https://dl.flathub.org/repo/flathub.flatpakrepo");

void desktopNotify(const QString &summary, const QString &body)
{
    QDBusInterface n(QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("/org/freedesktop/Notifications"),
                     QStringLiteral("org.freedesktop.Notifications"), QDBusConnection::sessionBus());
    n.asyncCall(QStringLiteral("Notify"), QStringLiteral("Store"), 0u, QStringLiteral("org.vinx.store"), summary, body,
                QStringList(), QVariantMap(), -1);
}
}

Flatpak::Flatpak(QObject *parent)
    : QObject(parent)
    , m_available(!QStandardPaths::findExecutable(QStringLiteral("flatpak")).isEmpty())
{
    refresh();
}

int Flatpak::parseProgress(const QString &output)
{
    static const QRegularExpression re(QStringLiteral("(\\d{1,3})\\s?%"));
    int last = -1;
    auto it = re.globalMatch(output);
    while (it.hasNext())
        last = qMin(100, it.next().captured(1).toInt());
    return last;
}

void Flatpak::refresh()
{
    if (!m_available)
        return;
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p] {
        const QVariantList apps = parseFlatpakColumns(QString::fromUtf8(p->readAllStandardOutput()),
                                                      {QStringLiteral("id"), QStringLiteral("name"), QStringLiteral("version")});
        p->deleteLater();
        QStringList ids;
        for (const QVariant &a : apps)
            ids.append(a.toMap().value(QStringLiteral("id")).toString());
        if (apps != m_installedApps) {
            m_installed = ids;
            m_installedApps = apps;
            Q_EMIT installedChanged();
        }
    });
    p->start(QStringLiteral("flatpak"), {QStringLiteral("list"), QStringLiteral("--app"),
                                         QStringLiteral("--columns=application,name,version")});
}

void Flatpak::search(const QString &query)
{
    const int serial = ++m_searchSerial;
    if (!m_available || query.trimmed().size() < 2) {
        m_results.clear();
        m_searching = false;
        Q_EMIT searchResultsChanged();
        return;
    }
    m_searching = true;
    Q_EMIT searchResultsChanged();
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p, serial] {
        p->deleteLater();
        if (serial != m_searchSerial)
            return;   // une recherche plus récente est en cours
        QVariantList all = parseFlatpakColumns(QString::fromUtf8(p->readAllStandardOutput()),
                                               {QStringLiteral("id"), QStringLiteral("name"), QStringLiteral("summary")});
        if (all.size() > 40)
            all = all.mid(0, 40);
        m_results = all;
        m_searching = false;
        Q_EMIT searchResultsChanged();
    });
    p->start(QStringLiteral("flatpak"), {QStringLiteral("search"), QStringLiteral("--columns=application,name,description"), query.trimmed()});
}

bool Flatpak::start(const QStringList &args, const QString &task, const QString &doneMessage)
{
    if (!m_available || m_process)
        return false;
    m_process = new QProcess(this);
    m_process->setProcessChannelMode(QProcess::MergedChannels);
    m_task = task;
    m_progress = 0;
    connect(m_process, &QProcess::readyRead, this, [this] {
        const int p = parseProgress(QString::fromUtf8(m_process->readAll()));
        if (p >= 0 && p != m_progress) {
            m_progress = p;
            Q_EMIT progressChanged();
        }
    });
    connect(m_process, &QProcess::finished, this, [this, doneMessage](int code, QProcess::ExitStatus status) {
        const bool ok = status == QProcess::NormalExit && code == 0;
        m_process->deleteLater();
        m_process = nullptr;
        m_progress = -1;
        Q_EMIT busyChanged();
        Q_EMIT progressChanged();
        const QString message = ok ? doneMessage : tr("L'opération « %1 » a échoué. Vérifiez la connexion à Internet.").arg(m_task);
        desktopNotify(ok ? tr("Store") : tr("Échec"), message);
        Q_EMIT finished(ok, message);
        refresh();
    });
    // Ajoute Flathub pour l'utilisateur si nécessaire, puis lance l'opération.
    const QString script = QStringLiteral("flatpak remote-add --user --if-not-exists flathub %1 && exec flatpak \"$@\"").arg(kFlathub);
    m_process->start(QStringLiteral("sh"), QStringList{QStringLiteral("-c"), script, QStringLiteral("flatpak")} + args);
    Q_EMIT busyChanged();
    Q_EMIT progressChanged();
    return true;
}

bool Flatpak::install(const QStringList &appIds, const QString &label)
{
    return start(QStringList{QStringLiteral("install"), QStringLiteral("--user"), QStringLiteral("--noninteractive"),
                             QStringLiteral("-y"), QStringLiteral("flathub")} + appIds,
                 tr("Installation de %1").arg(label), tr("%1 est installé.").arg(label));
}

bool Flatpak::uninstall(const QStringList &appIds, const QString &label)
{
    return start(QStringList{QStringLiteral("uninstall"), QStringLiteral("--user"), QStringLiteral("--noninteractive"),
                             QStringLiteral("-y")} + appIds,
                 tr("Suppression de %1").arg(label), tr("%1 a été supprimé.").arg(label));
}

bool Flatpak::launch(const QString &appId) const
{
    return QProcess::startDetached(QStringLiteral("flatpak"), {QStringLiteral("run"), appId});
}

void Flatpak::details(const QString &appId)
{
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p, appId] {
        QVariantMap m;
        for (const QString &raw : QString::fromUtf8(p->readAllStandardOutput()).split(QLatin1Char('\n'))) {
            const QString line = raw.trimmed();
            const QString key = line.section(QLatin1Char(':'), 0, 0).trimmed(), val = line.section(QLatin1Char(':'), 1).trimmed();
            if (key == QLatin1String("Version")) m.insert(QStringLiteral("version"), val);
            else if (key == QLatin1String("License")) m.insert(QStringLiteral("license"), val);
            else if (key == QLatin1String("Download")) m.insert(QStringLiteral("download"), val);
            else if (key == QLatin1String("Installed")) m.insert(QStringLiteral("installedSize"), val);
            else if (key == QLatin1String("Runtime")) m.insert(QStringLiteral("runtime"), val);
        }
        p->deleteLater();
        Q_EMIT detailsReady(appId, m);
    });
    p->start(QStringLiteral("flatpak"), {QStringLiteral("remote-info"), QStringLiteral("flathub"), appId});
}

QString Flatpak::iconUrl(const QString &appId) const
{
    if (appId.isEmpty())
        return {};
    const QString home = QDir::homePath();
    const QStringList roots = {home + QStringLiteral("/.local/share/flatpak"), QStringLiteral("/var/lib/flatpak")};
    for (const QString &root : roots) {
        for (const char *size : {"128x128", "64x64"}) {
            const QString cached = root + QStringLiteral("/appstream/flathub/x86_64/active/icons/") + QLatin1String(size) + QLatin1Char('/') + appId + QStringLiteral(".png");
            if (QFileInfo::exists(cached))
                return QUrl::fromLocalFile(cached).toString();
            const QString exported = root + QStringLiteral("/exports/share/icons/hicolor/") + QLatin1String(size) + QStringLiteral("/apps/") + appId + QStringLiteral(".png");
            if (QFileInfo::exists(exported))
                return QUrl::fromLocalFile(exported).toString();
        }
        const QString svg = root + QStringLiteral("/exports/share/icons/hicolor/scalable/apps/") + appId + QStringLiteral(".svg");
        if (QFileInfo::exists(svg))
            return QUrl::fromLocalFile(svg).toString();
    }
    return {};
}

bool Flatpak::appstreamStale(const QDateTime &lastUpdate, const QDateTime &now)
{
    return !lastUpdate.isValid() || lastUpdate.secsTo(now) > 24 * 3600 || lastUpdate > now.addSecs(3600);
}

void Flatpak::refreshAppstream()
{
    if (!m_available || m_appstreamRunning)
        return;
    QDateTime last;
    for (const QString &root : {QDir::homePath() + QStringLiteral("/.local/share/flatpak"), QStringLiteral("/var/lib/flatpak")}) {
        const QFileInfo active(root + QStringLiteral("/appstream/flathub/x86_64/active"));
        if (active.exists() && (!last.isValid() || active.lastModified() > last))
            last = active.lastModified();
    }
    if (!appstreamStale(last, QDateTime::currentDateTime()))
        return;
    m_appstreamRunning = true;
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p](int code, QProcess::ExitStatus status) {
        m_appstreamRunning = false;
        p->deleteLater();
        if (status == QProcess::NormalExit && code == 0) {
            ++m_iconsRevision;
            Q_EMIT iconsChanged();
        }
    });
    connect(p, &QProcess::errorOccurred, this, [this, p](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) { m_appstreamRunning = false; p->deleteLater(); }
    });
    p->start(QStringLiteral("flatpak"), {QStringLiteral("update"), QStringLiteral("--appstream"), QStringLiteral("--noninteractive"), QStringLiteral("flathub")});
}
