#include "session.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QFile>
#include <QProcess>
#include <QStandardPaths>

namespace {
const QString kLogin = QStringLiteral("org.freedesktop.login1");
}

Session::Session(QObject *parent)
    : QObject(parent)
{
}

QString Session::userName() const
{
    return qEnvironmentVariable("USER");
}

QString Session::osName() const
{
    QFile f(QStringLiteral("/etc/os-release"));
    if (f.open(QIODevice::ReadOnly)) {
        for (const QByteArray &line : f.readAll().split('\n')) {
            if (line.startsWith("PRETTY_NAME="))
                return QString::fromUtf8(line.mid(12)).remove(QLatin1Char('"'));
        }
    }
    return QStringLiteral("VinX OS");
}

void Session::callManager(const QString &method)
{
    QDBusInterface m(kLogin, QStringLiteral("/org/freedesktop/login1"), QStringLiteral("org.freedesktop.login1.Manager"),
                     QDBusConnection::systemBus());
    m.asyncCall(method, true);   // true = autorise une demande d'authentification si nécessaire
}

void Session::callSession(const QString &method)
{
    QDBusInterface s(kLogin, QStringLiteral("/org/freedesktop/login1/session/auto"), QStringLiteral("org.freedesktop.login1.Session"),
                     QDBusConnection::systemBus());
    s.asyncCall(method);
}

void Session::lock() { callSession(QStringLiteral("Lock")); }
void Session::logout() { callSession(QStringLiteral("Terminate")); }
void Session::suspend() { callManager(QStringLiteral("Suspend")); }
void Session::reboot() { callManager(QStringLiteral("Reboot")); }
void Session::powerOff() { callManager(QStringLiteral("PowerOff")); }

bool Session::launch(const QString &program, const QStringList &arguments)
{
    if (QStandardPaths::findExecutable(program).isEmpty())
        return false;
    return QProcess::startDetached(program, arguments);
}
