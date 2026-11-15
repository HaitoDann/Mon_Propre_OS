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
