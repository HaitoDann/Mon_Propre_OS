#pragma once

#include <QRegularExpression>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

// Analyse des sorties des outils de mise à jour (testées dans tests/tst_updates.cpp).

// « apt list --upgradable » :
// firefox-esr/stable-security 128.5.0esr-1~deb13u1 amd64 [upgradable from: 128.4.0esr-1~deb13u1]
inline QVariantList parseAptUpgradable(const QString &out)
{
    static const QRegularExpression re(QStringLiteral("^([^/\\s]+)/\\S+\\s+(\\S+)\\s+\\S+\\s+\\[[^:]*:\\s*([^\\]]+)\\]"));
    QVariantList list;
    for (const QString &line : out.split(QLatin1Char('\n'))) {
        const auto m = re.match(line.trimmed());
        if (m.hasMatch())
            list.append(QVariantMap{{QStringLiteral("name"), m.captured(1)},
                                    {QStringLiteral("version"), m.captured(2)},
                                    {QStringLiteral("from"), m.captured(3).trimmed()}});
    }
    return list;
}

// Sorties Flatpak en colonnes séparées par des tabulations (« --columns=a,b,c »).
// keys : noms des colonnes ; les lignes incomplètes ou d'en-tête sont ignorées.
inline QVariantList parseFlatpakColumns(const QString &out, const QStringList &keys)
{
    QVariantList list;
    for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const QStringList cols = line.split(QLatin1Char('\t'));
        if (cols.size() < keys.size() || cols.first().trimmed().isEmpty())
            continue;
        if (!cols.first().contains(QLatin1Char('.')))   // identifiant d'application : org.exemple.App
            continue;
        QVariantMap m;
        for (int i = 0; i < keys.size(); ++i)
            m.insert(keys[i], cols[i].trimmed());
        list.append(m);
    }
    return list;
}

// Journal d'APT (/var/log/apt/history.log) : une entrée par opération, la plus récente d'abord.
// [{ date: "2026-11-17 21:37", upgraded, installed, removed, packages: "firefox-esr, vinx-shell…" }]
inline QVariantList parseAptHistory(const QString &log, int limit = 50)
{
    QVariantList out;
    QVariantMap cur;
    int up = 0, in = 0, rm = 0;
    QStringList names;
    // Paquets d'une ligne « Upgrade: a:amd64 (1, 2), b (3, 4) » : on retire les parenthèses.
    static const QRegularExpression parens(QStringLiteral("\\([^)]*\\)"));
    auto packages = [](const QString &value) {
        QString v = value;
        v.remove(parens);
        QStringList list;
        for (QString p : v.split(QLatin1Char(','), Qt::SkipEmptyParts)) {
            p = p.trimmed();
            p = p.section(QLatin1Char(':'), 0, 0);
            if (!p.isEmpty())
                list.append(p);
        }
        return list;
    };
    auto flush = [&] {
        if (!cur.isEmpty() && (up + in + rm) > 0) {
            cur.insert(QStringLiteral("upgraded"), up);
            cur.insert(QStringLiteral("installed"), in);
            cur.insert(QStringLiteral("removed"), rm);
            QStringList shown = names.mid(0, 4);
            QString text = shown.join(QStringLiteral(", "));
            if (names.size() > 4)
                text += QStringLiteral("…");
            cur.insert(QStringLiteral("packages"), text);
            out.prepend(cur);
        }
        cur.clear();
        up = in = rm = 0;
        names.clear();
    };
    for (const QString &raw : log.split(QLatin1Char('\n'))) {
        const QString line = raw.trimmed();
        if (line.startsWith(QLatin1String("Start-Date:"))) {
            flush();
            // « 2026-11-17  21:37:41 » → « 2026-11-17 21:37 »
            const QStringList parts = line.mid(11).simplified().split(QLatin1Char(' '));
            cur.insert(QStringLiteral("date"), parts.value(0) + QLatin1Char(' ') + parts.value(1).left(5));
        } else if (line.startsWith(QLatin1String("Upgrade:"))) {
            const auto l = packages(line.mid(8)); up += l.size(); names += l;
        } else if (line.startsWith(QLatin1String("Install:")) || line.startsWith(QLatin1String("Reinstall:"))) {
            const auto l = packages(line.section(QLatin1Char(':'), 1)); in += l.size(); names += l;
        } else if (line.startsWith(QLatin1String("Remove:")) || line.startsWith(QLatin1String("Purge:"))) {
            const auto l = packages(line.section(QLatin1Char(':'), 1)); rm += l.size(); names += l;
        }
    }
    flush();
    return out.mid(0, limit);
}

// /etc/vinx-release : VINX_VERSION="0.17.1"
inline QString parseVinxRelease(const QString &text)
{
    static const QRegularExpression re(QStringLiteral("^VINX_VERSION=\"?([^\"\\n]*)\"?"), QRegularExpression::MultilineOption);
    return re.match(text).captured(1).trimmed();
}

// « timeshift --list --scripted » : lignes « 0    >  2026-11-15_10-02-01  O     Avant mise à jour »
// → [{ name, date: "2026-11-15 10:02", tags, comment }], le plus récent d'abord.
inline QVariantList parseTimeshiftList(const QString &out)
{
    static const QRegularExpression re(QStringLiteral("^\\s*\\d+\\s+>\\s+(\\d{4}-\\d{2}-\\d{2}_\\d{2}-\\d{2}-\\d{2})\\s*([OBHDWM]*)\\s*(.*)$"));
    QVariantList list;
    for (const QString &line : out.split(QLatin1Char('\n'))) {
        const auto m = re.match(line);
        if (!m.hasMatch())
            continue;
        const QString name = m.captured(1);
        const QString date = name.left(10) + QLatin1Char(' ') + name.mid(11, 5).replace(QLatin1Char('-'), QLatin1Char(':'));
        list.prepend(QVariantMap{{QStringLiteral("name"), name}, {QStringLiteral("date"), date},
                                 {QStringLiteral("tags"), m.captured(2)}, {QStringLiteral("comment"), m.captured(3).trimmed()}});
    }
    return list;
}
