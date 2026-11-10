#include "applications.h"
#include "desktopentry.h"

#include <QCollator>
#include <QDir>
#include <QSet>
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

QVariantList Applications::all() const
{
    struct App { QString id, name, icon, generic, keywords; };
    QList<App> apps;
    QSet<QString> seen;
    // Les premiers dossiers XDG (utilisateur) masquent les suivants (système).
    for (const QString &dir : QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation)) {
        const auto files = QDir(dir).entryList({QStringLiteral("*.desktop")}, QDir::Files);
        for (const QString &file : files) {
            const QString id = file.chopped(8);
            if (seen.contains(id))
                continue;
            seen.insert(id);
            QFile f(dir + QLatin1Char('/') + file);
            if (!f.open(QIODevice::ReadOnly))
                continue;
            const DesktopEntry e = parseDesktopEntry(f.readAll());
            if (e.valid && !e.hidden && !e.exec.isEmpty())
                apps.append({id, e.name, e.icon, e.genericName, e.keywords});
        }
    }
    QCollator collator;
    collator.setCaseSensitivity(Qt::CaseInsensitive);
    std::sort(apps.begin(), apps.end(), [&](const App &a, const App &b) { return collator.compare(a.name, b.name) < 0; });
    QVariantList out;
    for (const App &a : apps)
        out.append(QVariantMap{{QStringLiteral("id"), a.id}, {QStringLiteral("name"), a.name}, {QStringLiteral("icon"), a.icon},
                               {QStringLiteral("genericName"), a.generic}, {QStringLiteral("keywords"), a.keywords}});
    return out;
}
