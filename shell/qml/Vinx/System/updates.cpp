#include "updates.h"
#include "updateparse.h"

#include <QDBusConnection>
#include <QDBusInterface>

#include <QCoreApplication>
#include <QProcess>
#include <QStandardPaths>
#include <QSysInfo>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>

namespace {
void desktopNotify(const QString &summary, const QString &body)
{
    QDBusInterface n(QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("/org/freedesktop/Notifications"),
                     QStringLiteral("org.freedesktop.Notifications"), QDBusConnection::sessionBus());
    n.asyncCall(QStringLiteral("Notify"), QStringLiteral("Store"), 0u, QStringLiteral("org.vinx.store"), summary, body,
                QStringList(), QVariantMap{{QStringLiteral("desktop-entry"), QStringLiteral("org.vinx.store")}}, -1);
}
}

Updates::Updates(QObject *parent)
    : QObject(parent)
{
    // Suivi de l'installation en arrière-plan, y compris lancée par un autre processus.
    m_poll.setInterval(1000);
    connect(&m_poll, &QTimer::timeout, this, &Updates::readStatus);
    m_watcher.addPath(qEnvironmentVariable("XDG_RUNTIME_DIR", QStringLiteral("/tmp")));
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &Updates::readStatus);
    readStatus();
    m_pkcon = !QStandardPaths::findExecutable(QStringLiteral("pkcon")).isEmpty();
    m_flatpak = !QStandardPaths::findExecutable(QStringLiteral("flatpak")).isEmpty();
}

void Updates::setStatus(const QString &s)
{
    m_status = s;
    Q_EMIT stateChanged();
}

void Updates::run(const QString &program, const QStringList &args, std::function<void(bool, const QString &)> done)
{
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [p, done](int code, QProcess::ExitStatus st) {
        p->deleteLater();
        done(st == QProcess::NormalExit && code == 0, QString::fromUtf8(p->readAllStandardOutput()));
    });
    connect(p, &QProcess::errorOccurred, this, [p, done](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) { p->deleteLater(); done(false, {}); }
    });
    p->start(program, args);
}

void Updates::end(bool ok, const QString &message)
{
    m_step = Idle;
    setStatus(ok ? QString() : message);
    Q_EMIT finished(ok, message);
}

void Updates::check()
{
    if (m_step != Idle)
        return;
    m_step = Check;
    setStatus(tr("Recherche des mises à jour…"));

    auto listFlatpak = [this] {
        if (!m_flatpak) {
            m_apps.clear();
            m_lastCheck = QDateTime::currentDateTime();
            Q_EMIT listChanged();
            end(true, {});
            return;
        }
        run(QStringLiteral("flatpak"), {QStringLiteral("remote-ls"), QStringLiteral("--updates"), QStringLiteral("--app"),
                                        QStringLiteral("--columns=application,name,version")},
            [this](bool, const QString &out) {
                m_apps = parseFlatpakColumns(out, {QStringLiteral("id"), QStringLiteral("name"), QStringLiteral("version")});
                m_lastCheck = QDateTime::currentDateTime();
                Q_EMIT listChanged();
                end(true, {});
            });
    };
    auto listApt = [this, listFlatpak] {
        run(QStringLiteral("apt"), {QStringLiteral("list"), QStringLiteral("--upgradable")},
            [this, listFlatpak](bool, const QString &out) {
                m_system = parseAptUpgradable(out);
                listFlatpak();
            });
    };
    // Rafraîchit l'index des paquets (PackageKit l'autorise sans mot de passe en session locale).
    if (m_pkcon)
        run(QStringLiteral("pkcon"), {QStringLiteral("refresh"), QStringLiteral("--plain")}, [listApt](bool, const QString &) { listApt(); });
    else
        listApt();
}


void Updates::applyAll(bool appsOnly)
{
    if (applying() || (!appsOnly && count() == 0))
        return;
    // Processus détaché : l'installation continue si le Store est fermé ; l'état est écrit dans
    // $XDG_RUNTIME_DIR/vinx-update.json et suivi par readStatus().
    const QString helper = QStringLiteral("/usr/lib/vinx/vinx-update");
    QStringList args;
    if (appsOnly)
        args << QStringLiteral("--apps-only");
    if (!QProcess::startDetached(helper, args)) {
        Q_EMIT finished(false, tr("Impossible de lancer les mises à jour."));
        return;
    }
    m_bgRunning = true;
    m_bgPercent = 0;
    m_bgStep = appsOnly ? QStringLiteral("apps") : QStringLiteral("system");
    m_poll.start();
    Q_EMIT stateChanged();
}

static QString statusPath()
{
    const QString dir = qEnvironmentVariable("XDG_RUNTIME_DIR", QStringLiteral("/tmp"));
    return dir + QStringLiteral("/vinx-update.json");
}

void Updates::readStatus()
{
    QFile f(statusPath());
    if (!f.open(QIODevice::ReadOnly))
        return;
    const QJsonObject o = QJsonDocument::fromJson(f.readAll()).object();
    if (o.isEmpty())
        return;
    const QString state = o.value(QStringLiteral("state")).toString();
    const bool running = state == QLatin1String("running")
        && QDateTime::currentSecsSinceEpoch() - o.value(QStringLiteral("time")).toInteger() < 3600;
    const bool wasRunning = m_bgRunning;
    m_bgRunning = running;
    m_bgPercent = o.value(QStringLiteral("percent")).toInt();
    m_bgStep = o.value(QStringLiteral("step")).toString();
    if (running && !m_poll.isActive())
        m_poll.start();
    if (!running)
        m_poll.stop();
    Q_EMIT stateChanged();
    if (wasRunning && !running) {
        const bool ok = state == QLatin1String("done");
        Q_EMIT finished(ok, ok ? tr("Le système est à jour.") : tr("Certaines mises à jour n'ont pas pu être installées."));
        check();
    }
}

QString Updates::stepLabel() const
{
    if (!m_bgRunning)
        return {};
    return m_bgStep == QLatin1String("apps") ? tr("Mise à jour des applications") : tr("Mise à jour du système");
}

namespace {
QString readText(const QString &path)
{
    QFile f(path);
    return f.open(QIODevice::ReadOnly) ? QString::fromUtf8(f.readAll()) : QString();
}
}

QVariantMap Updates::versions() const
{
    return {{QStringLiteral("vinxOs"), parseVinxRelease(readText(QStringLiteral("/etc/vinx-release")))},
            // Version du bureau VinX : celle des applications VinX (même paquet vinx-shell).
            {QStringLiteral("desktop"), QCoreApplication::applicationVersion()},
            {QStringLiteral("debian"), readText(QStringLiteral("/etc/debian_version")).trimmed()},
            {QStringLiteral("kernel"), QSysInfo::kernelVersion()}};
}

QVariantList Updates::history() const
{
    return parseAptHistory(readText(QStringLiteral("/var/log/apt/history.log")));
}

bool Updates::snapshotsEnabled() const
{
    return QFile::exists(QStringLiteral("/etc/timeshift/timeshift.json"));
}

QVariantList Updates::snapshots() const
{
    return parseTimeshiftList(readText(QStringLiteral("/var/lib/vinx/snapshots.list")));
}

void Updates::snapshotAction(const QString &action, const QString &argument)
{
    QStringList args{QStringLiteral("/usr/lib/vinx/vinx-snapshots"), action};
    if (!argument.isEmpty())
        args << argument;
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [=](int code, QProcess::ExitStatus st) {
        p->deleteLater();
        Q_EMIT snapshotFinished(action, st == QProcess::NormalExit && code == 0);
    });
    p->start(QStringLiteral("pkexec"), args);
}
