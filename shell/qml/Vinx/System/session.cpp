#include "session.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSysInfo>
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

bool Session::fileExists(const QString &path) const
{
    return !path.isEmpty() && QFile::exists(path);
}

void Session::invokeKWinShortcut(const QString &name)
{
    QDBusInterface kwin(QStringLiteral("org.kde.kglobalaccel"), QStringLiteral("/component/kwin"),
                        QStringLiteral("org.kde.kglobalaccel.Component"), QDBusConnection::sessionBus());
    kwin.asyncCall(QStringLiteral("invokeShortcut"), name);
}

QVariantList Session::wallpapers() const
{
    QVariantList out;
    const QDir root(QStringLiteral("/usr/share/wallpapers"));
    for (const QString &pkg : root.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
        const QDir images(root.filePath(pkg + QStringLiteral("/contents/images")));
        QStringList files = images.entryList({QStringLiteral("*.png"), QStringLiteral("*.jpg"), QStringLiteral("*.jpeg")}, QDir::Files);
        if (files.isEmpty())
            continue;
        // Préfère la plus grande définition (noms « LARGEURxHAUTEUR.ext »).
        std::sort(files.begin(), files.end(), [](const QString &a, const QString &b) {
            return a.section(QLatin1Char('x'), 0, 0).toInt() > b.section(QLatin1Char('x'), 0, 0).toInt();
        });
        QString name = pkg;
        QFile meta(root.filePath(pkg + QStringLiteral("/metadata.json")));
        if (meta.open(QIODevice::ReadOnly)) {
            const QString n = QJsonDocument::fromJson(meta.readAll()).object().value(QStringLiteral("KPlugin")).toObject()
                                  .value(QStringLiteral("Name")).toString();
            if (!n.isEmpty())
                name = n;
        }
        const QString preview = root.filePath(pkg + QStringLiteral("/contents/screenshot.png"));
        out.append(QVariantMap{{QStringLiteral("name"), name}, {QStringLiteral("path"), images.filePath(files.first())},
                               {QStringLiteral("preview"), QFile::exists(preview) ? preview : images.filePath(files.last())}});
    }
    return out;
}

QString Session::kernelVersion() const { return QSysInfo::kernelVersion(); }
QString Session::hostName() const { return QSysInfo::machineHostName(); }
