#include "applications.h"
#include "desktopentry.h"

#include <QStandardPaths>

namespace {
QString fileFor(QString id)
{
    if (!id.endsWith(QLatin1String(".desktop")))
        id += QLatin1String(".desktop");
    return QStandardPaths::locate(QStandardPaths::ApplicationsLocation, id);
}

DesktopEntry entryFor(const QString &id)
{
    const QString path = fileFor(id);
    if (path.isEmpty())
        return {};
    QFile f(path);
    return f.open(QIODevice::ReadOnly) ? parseDesktopEntry(f.readAll()) : DesktopEntry();
}
}

Applications::Applications(QObject *parent)
    : QObject(parent)
{
}

QVariantMap Applications::info(const QString &desktopId) const
{
    const DesktopEntry e = entryFor(desktopId);
    return {{QStringLiteral("valid"), e.valid}, {QStringLiteral("name"), e.name},
            {QStringLiteral("icon"), e.icon}, {QStringLiteral("exec"), e.exec}};
}

bool Applications::launch(const QString &desktopId) const
{
    const DesktopEntry e = entryFor(desktopId);
    QStringList args = desktopExecArguments(e.exec);
    if (!e.valid || args.isEmpty())
        return false;
    const QString program = args.takeFirst();
    return QProcess::startDetached(program, args);
}
