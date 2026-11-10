#pragma once

#include <algorithm>

#include <QFile>
#include <QLocale>
#include <QProcess>
#include <QRegularExpression>
#include <QString>
#include <QStringList>

// Lecture minimale d'un fichier .desktop (section [Desktop Entry]).
struct DesktopEntry {
    bool valid = false;
    QString name;
    QString icon;
    QString exec;
};

inline DesktopEntry parseDesktopEntry(const QByteArray &content, const QString &lang = QLocale().name())
{
    DesktopEntry e;
    const QString shortLang = lang.section(QLatin1Char('_'), 0, 0);
    QString nameLang, nameShort;
    bool inEntry = false;
    for (const QByteArray &raw : content.split('\n')) {
        const QString line = QString::fromUtf8(raw).trimmed();
        if (line.startsWith(QLatin1Char('['))) {
            inEntry = line == QLatin1String("[Desktop Entry]");
            continue;
        }
        if (!inEntry || line.startsWith(QLatin1Char('#')))
            continue;
        const int eq = line.indexOf(QLatin1Char('='));
        if (eq < 0)
            continue;
        const QString key = line.left(eq).trimmed();
        const QString value = line.mid(eq + 1).trimmed();
        if (key == QLatin1String("Name")) e.name = value;
        else if (key == QStringLiteral("Name[%1]").arg(lang)) nameLang = value;
        else if (key == QStringLiteral("Name[%1]").arg(shortLang)) nameShort = value;
        else if (key == QLatin1String("Icon")) e.icon = value;
        else if (key == QLatin1String("Exec")) e.exec = value;
    }
    if (!nameLang.isEmpty()) e.name = nameLang;
    else if (!nameShort.isEmpty()) e.name = nameShort;
    e.valid = !e.name.isEmpty();
    return e;
}

// Ligne de commande issue de Exec, sans les codes de champ (%f, %U, %i…).
inline QStringList desktopExecArguments(const QString &exec)
{
    QStringList args = QProcess::splitCommand(exec);
    static const QRegularExpression field(QStringLiteral("^%[fFuUdDnNickvm]$"));
    args.erase(std::remove_if(args.begin(), args.end(), [](const QString &a) { return field.match(a).hasMatch(); }), args.end());
    for (QString &a : args)
        a.replace(QLatin1String("%%"), QLatin1String("%"));
    return args;
}
