#include "flatpak.h"

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
        QStringList ids = QString::fromUtf8(p->readAllStandardOutput()).split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (QString &id : ids)
            id = id.trimmed();
        p->deleteLater();
        if (ids != m_installed) {
            m_installed = ids;
            Q_EMIT installedChanged();
        }
    });
    p->start(QStringLiteral("flatpak"), {QStringLiteral("list"), QStringLiteral("--app"), QStringLiteral("--columns=application")});
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
