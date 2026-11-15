#include "updates.h"
#include "updateparse.h"

#include <QDBusConnection>
#include <QDBusInterface>

#include <QStandardPaths>

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

void Updates::applied(bool ok)
{
    m_step = Idle;
    const QString message = ok ? tr("Le système est à jour.")
                               : tr("Certaines mises à jour n'ont pas pu être installées.");
    desktopNotify(tr("Mises à jour"), message);
    Q_EMIT finished(ok, message);
    check();   // met la liste à jour
}

void Updates::applyAll()
{
    if (m_step != Idle || count() == 0)
        return;
    m_step = Apply;
    const bool doSystem = !m_system.isEmpty() && m_pkcon;
    const bool doApps = !m_apps.isEmpty() && m_flatpak;

    auto applyApps = [this, doApps](bool systemOk, const QString &) {
        if (!doApps)
            return applied(systemOk);
        setStatus(tr("Mise à jour des applications…"));
        run(QStringLiteral("flatpak"), {QStringLiteral("update"), QStringLiteral("-y"), QStringLiteral("--noninteractive")},
            [this, systemOk](bool ok, const QString &) { applied(systemOk && ok); });
    };
    if (doSystem) {
        // PackageKit demande le mot de passe administrateur (agent polkit de la session).
        setStatus(tr("Installation des mises à jour du système…"));
        run(QStringLiteral("pkcon"), {QStringLiteral("update"), QStringLiteral("-y"), QStringLiteral("--plain")}, applyApps);
    } else {
        applyApps(true, {});
    }
}
