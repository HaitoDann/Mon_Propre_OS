#pragma once

// Lecture des fichiers de /proc pour le Moniteur système (ADR 0035). Fonctions pures,
// testées dans tests/tst_monitor.cpp.

#include <QByteArray>
#include <QList>
#include <QProcess>
#include <QRegularExpression>
#include <QString>
#include <QStringList>

namespace ProcParse {

// /proc/<pid>/stat. Le nom (comm) est entre parenthèses et peut contenir espaces et parenthèses.
struct Stat {
    bool ok = false;
    QString comm;
    char state = '?';
    int ppid = 0;
    quint64 ticks = 0;     // utime + stime, en tops d'horloge
    int nice = 0;
    qint64 rssPages = 0;
};

inline Stat parseStat(const QByteArray &line)
{
    Stat s;
    const int l = line.indexOf('(');
    const int r = line.lastIndexOf(')');
    if (l < 0 || r < l || r + 2 > line.size())
        return s;
    s.comm = QString::fromUtf8(line.mid(l + 1, r - l - 1));
    // Champ n de la page de manuel proc(5) → f[n - 3].
    const QList<QByteArray> f = line.mid(r + 2).trimmed().split(' ');
    if (f.size() < 22)
        return s;
    s.state = f.at(0).isEmpty() ? '?' : f.at(0).at(0);
    s.ppid = f.at(1).toInt();
    s.ticks = f.at(11).toULongLong() + f.at(12).toULongLong();
    s.nice = f.at(16).toInt();
    s.rssPages = f.at(21).toLongLong();
    s.ok = true;
    return s;
}

// Valeur numérique d'une ligne « Clé:  valeur … » (status, meminfo, smaps_rollup, io).
inline qint64 field(const QByteArray &content, const QByteArray &key)
{
    for (const QByteArray &line : content.split('\n')) {
        if (line.startsWith(key) && line.size() > key.size() && line.at(key.size()) == ':') {
            const QList<QByteArray> parts = line.mid(key.size() + 1).simplified().split(' ');
            return parts.isEmpty() ? -1 : parts.first().toLongLong();
        }
    }
    return -1;
}

// Premier identifiant réel de « Uid: » dans /proc/<pid>/status.
inline qint64 uid(const QByteArray &status) { return field(status, "Uid"); }

// /proc/<pid>/cmdline : arguments séparés par des octets nuls.
inline QString commandLine(const QByteArray &raw)
{
    QByteArray c = raw;
    while (c.endsWith('\0'))
        c.chop(1);
    c.replace('\0', ' ');
    return QString::fromUtf8(c);
}

// Ligne « cpu » agrégée de /proc/stat.
struct CpuTimes {
    quint64 total = 0;
    quint64 idle = 0;
};

inline CpuTimes parseCpu(const QByteArray &procStat)
{
    CpuTimes t;
    const QByteArray first = procStat.left(procStat.indexOf('\n'));
    if (!first.startsWith("cpu "))
        return t;
    const QList<QByteArray> f = first.simplified().split(' ');
    // user nice system idle iowait irq softirq steal (guest est déjà compté dans user)
    for (int i = 1; i < f.size() && i <= 8; ++i)
        t.total += f.at(i).toULongLong();
    if (f.size() > 5)
        t.idle = f.at(4).toULongLong() + f.at(5).toULongLong();
    return t;
}

// Mémoire en kio : totale et disponible (MemAvailable).
struct Memory {
    qint64 totalKb = 0;
    qint64 availableKb = 0;
};

inline Memory parseMeminfo(const QByteArray &content)
{
    return {qMax<qint64>(0, field(content, "MemTotal")), qMax<qint64>(0, field(content, "MemAvailable"))};
}

struct Counters {
    quint64 in = 0;
    quint64 out = 0;
};

// /proc/net/dev : octets reçus et émis, toutes interfaces sauf la boucle locale.
inline Counters parseNetDev(const QByteArray &content)
{
    Counters c;
    for (const QByteArray &line : content.split('\n')) {
        const int colon = line.indexOf(':');
        if (colon < 0)
            continue;
        if (line.left(colon).trimmed() == "lo")
            continue;
        const QList<QByteArray> f = line.mid(colon + 1).simplified().split(' ');
        if (f.size() < 9)
            continue;
        c.in += f.at(0).toULongLong();
        c.out += f.at(8).toULongLong();
    }
    return c;
}

// /proc/diskstats : octets lus et écrits sur les disques entiers (pas les partitions).
inline Counters parseDiskstats(const QByteArray &content)
{
    static const QRegularExpression disk(QStringLiteral("^(sd[a-z]+|vd[a-z]+|xvd[a-z]+|hd[a-z]+|nvme\\d+n\\d+|mmcblk\\d+)$"));
    Counters c;
    for (const QByteArray &line : content.split('\n')) {
        const QList<QByteArray> f = line.simplified().split(' ');
        if (f.size() < 10 || !disk.match(QString::fromLatin1(f.at(2))).hasMatch())
            continue;
        c.in += f.at(5).toULongLong() * 512;
        c.out += f.at(9).toULongLong() * 512;
    }
    return c;
}

// /proc/<pid>/io : octets réellement lus et écrits sur disque.
inline Counters parseIo(const QByteArray &content)
{
    return {quint64(qMax<qint64>(0, field(content, "read_bytes"))), quint64(qMax<qint64>(0, field(content, "write_bytes")))};
}

// « \x2d » → « - » dans un nom d'unité systemd.
inline QString unescapeUnit(const QString &s)
{
    QString out;
    for (int i = 0; i < s.size(); ++i) {
        if (s.at(i) == QLatin1Char('\\') && i + 3 < s.size() && s.at(i + 1) == QLatin1Char('x')) {
            bool ok = false;
            const int code = s.mid(i + 2, 2).toInt(&ok, 16);
            if (ok) {
                out += QChar(code);
                i += 3;
                continue;
            }
        }
        out += s.at(i);
    }
    return out;
}

// Identifiant d'application (.desktop) d'après le groupe de contrôle systemd, selon la convention
// XDG : app[-<lanceur>]-<id>[@<aléa>].service ou app[-<lanceur>]-<id>-<aléa>.scope.
// Chaîne vide si le processus n'est pas dans une unité d'application.
inline QString appIdFromCgroup(const QByteArray &cgroup)
{
    QString unit;
    for (const QByteArray &line : cgroup.split('\n')) {
        const QList<QByteArray> parts = line.split('/');
        for (const QByteArray &p : parts) {
            if (p.startsWith("app-") && (p.endsWith(".scope") || p.endsWith(".service")))
                unit = QString::fromUtf8(p);   // la plus profonde l'emporte
        }
    }
    if (unit.isEmpty())
        return {};
    const bool scope = unit.endsWith(QLatin1String(".scope"));
    unit.chop(scope ? 6 : 8);
    unit.remove(0, 4);
    const int at = unit.indexOf(QLatin1Char('@'));
    if (at >= 0) {
        unit.truncate(at);
    } else if (scope || unit.count(QLatin1Char('-')) > 0) {
        const int dash = unit.lastIndexOf(QLatin1Char('-'));
        // Suffixe aléatoire : chiffres hexadécimaux uniquement.
        static const QRegularExpression rnd(QStringLiteral("^[0-9a-f]+$"));
        if (dash > 0 && rnd.match(unit.mid(dash + 1)).hasMatch())
            unit.truncate(dash);
    }
    for (const QLatin1String launcher : {QLatin1String("flatpak-"), QLatin1String("gnome-"), QLatin1String("kde-")}) {
        if (unit.startsWith(launcher) && unit.size() > launcher.size()) {
            unit.remove(0, launcher.size());
            break;
        }
    }
    return unescapeUnit(unit);
}

// Nom de programme d'une ligne Exec : « env A=B firefox-esr %u » → « firefox-esr »,
// « flatpak run org.gimp.GIMP » → « org.gimp.GIMP », « sh -c "pkexec calamares" » → « calamares ».
// Un interpréteur de commandes nu (sh, bash…) n'est jamais un nom d'application : sinon tous
// les scripts du système seraient attribués à ce lanceur.
inline QString execProgram(const QStringList &args)
{
    static const QStringList wrappers = {QStringLiteral("pkexec"), QStringLiteral("sudo"), QStringLiteral("nice"),
                                         QStringLiteral("ionice"), QStringLiteral("nohup"), QStringLiteral("setsid")};
    static const QStringList shells = {QStringLiteral("sh"), QStringLiteral("bash"), QStringLiteral("dash"), QStringLiteral("zsh")};
    int i = 0;
    while (i < args.size()) {
        const QString name = args.at(i).section(QLatin1Char('/'), -1);
        if (name == QLatin1String("env")) {
            ++i;
            while (i < args.size() && (args.at(i).contains(QLatin1Char('=')) || args.at(i).startsWith(QLatin1Char('-'))))
                ++i;
        } else if (wrappers.contains(name)) {
            ++i;
            while (i < args.size() && args.at(i).startsWith(QLatin1Char('-')))
                ++i;
        } else if (shells.contains(name)) {
            // « sh -c "commande" » : on analyse la commande ; sinon rien d'identifiable.
            const int c = args.indexOf(QStringLiteral("-c"), i + 1);
            if (c < 0 || c + 1 >= args.size())
                return {};
            return execProgram(QProcess::splitCommand(args.at(c + 1)));
        } else {
            break;
        }
    }
    if (i < args.size() && args.at(i).endsWith(QLatin1String("flatpak"))) {
        for (int j = i + 1; j < args.size(); ++j) {
            if (!args.at(j).startsWith(QLatin1Char('-')) && args.at(j) != QLatin1String("run"))
                return args.at(j);
        }
        return {};
    }
    if (i >= args.size())
        return {};
    return args.at(i).section(QLatin1Char('/'), -1);
}

} // namespace ProcParse
