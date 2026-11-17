#pragma once

#include <QRegularExpression>
#include <QUrl>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

// Analyse des sorties des outils système (testées dans tests/tst_sysparse.cpp).

// Découpe une ligne « nmcli -t » : champs séparés par « : », « \: » et « \\ » échappés.
inline QStringList splitNmcliTerse(const QString &line)
{
    QStringList out;
    QString cur;
    for (int i = 0; i < line.size(); ++i) {
        const QChar c = line.at(i);
        if (c == QLatin1Char('\\') && i + 1 < line.size()) {
            cur += line.at(++i);
        } else if (c == QLatin1Char(':')) {
            out << cur;
            cur.clear();
        } else {
            cur += c;
        }
    }
    out << cur;
    return out;
}

// « nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list » → un réseau par nom (le plus fort),
// triés : réseau actif, puis force du signal. Les réseaux sans nom (cachés) sont ignorés.
inline QVariantList parseNmcliWifi(const QString &out)
{
    QVariantMap bySsid;
    for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const QStringList f = splitNmcliTerse(line);
        if (f.size() < 4 || f[1].isEmpty())
            continue;
        const bool active = f[0].trimmed() == QLatin1String("*");
        const int signal = f[2].toInt();
        const QString security = f[3].trimmed();
        const QVariantMap prev = bySsid.value(f[1]).toMap();
        if (!prev.isEmpty() && !active && prev.value(QStringLiteral("signal")).toInt() >= signal && !prev.value(QStringLiteral("active")).toBool())
            continue;
        if (!prev.isEmpty() && prev.value(QStringLiteral("active")).toBool())
            continue;
        bySsid.insert(f[1], QVariantMap{
            {QStringLiteral("ssid"), f[1]},
            {QStringLiteral("signal"), signal},
            {QStringLiteral("secure"), !security.isEmpty() && security != QLatin1String("--")},
            {QStringLiteral("security"), security},
            {QStringLiteral("active"), active},
        });
    }
    QVariantList list = bySsid.values();
    std::sort(list.begin(), list.end(), [](const QVariant &a, const QVariant &b) {
        const QVariantMap x = a.toMap(), y = b.toMap();
        if (x.value(QStringLiteral("active")).toBool() != y.value(QStringLiteral("active")).toBool())
            return x.value(QStringLiteral("active")).toBool();
        return x.value(QStringLiteral("signal")).toInt() > y.value(QStringLiteral("signal")).toInt();
    });
    return list;
}

// « nmcli -t -f NAME,TYPE connection show » → noms des réseaux Wi-Fi enregistrés.
inline QStringList parseNmcliKnownWifi(const QString &out)
{
    QStringList names;
    for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const QStringList f = splitNmcliTerse(line);
        if (f.size() >= 2 && f[1] == QLatin1String("802-11-wireless"))
            names << f[0];
    }
    return names;
}

// « lspci -mm -nn » : "00:02.0" "VGA compatible controller [0300]" "Intel Corporation [8086]" "Device [46a6]" …
inline QVariantList parseLspci(const QString &out)
{
    static const QRegularExpression field(QStringLiteral("\"([^\"]*)\""));
    static const QRegularExpression code(QStringLiteral("\\s*\\[([0-9a-fA-F]{4})\\]$"));
    QVariantList devices;
    for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        QStringList f;
        auto it = field.globalMatch(line);
        while (it.hasNext())
            f << it.next().captured(1);
        if (f.size() < 3)
            continue;
        auto strip = [](QString s, QString *id) {
            const auto m = code.match(s);
            if (m.hasMatch()) {
                if (id) *id = m.captured(1).toLower();
                s.truncate(m.capturedStart());
            }
            return s.trimmed();
        };
        QString classId, vendorId, deviceId;
        const QString cls = strip(f[0], &classId);
        const QString vendor = strip(f[1], &vendorId);
        const QString name = strip(f[2], &deviceId);
        devices.append(QVariantMap{{QStringLiteral("slot"), line.section(QLatin1Char(' '), 0, 0)},
                                   {QStringLiteral("class"), cls}, {QStringLiteral("classId"), classId},
                                   {QStringLiteral("vendor"), vendor}, {QStringLiteral("vendorId"), vendorId},
                                   {QStringLiteral("name"), name}, {QStringLiteral("deviceId"), deviceId}});
    }
    return devices;
}

// « lpstat -p -d » : imprimantes, état et imprimante par défaut.
inline QVariantList parseLpstat(const QString &out)
{
    static const QRegularExpression printer(QStringLiteral("^(?:printer|imprimante) (\\S+) (.*)$"));
    static const QRegularExpression def(QStringLiteral("^(?:system default destination|destination système par défaut)\\s*:\\s*(\\S+)"));
    QString defaultName;
    QVariantList list;
    for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const auto d = def.match(line);
        if (d.hasMatch()) {
            defaultName = d.captured(1);
            continue;
        }
        const auto m = printer.match(line);
        if (!m.hasMatch())
            continue;
        const QString state = m.captured(2);
        const QString status = state.contains(QLatin1String("disabled")) || state.contains(QLatin1String("désactivée")) ? QStringLiteral("disabled")
                             : state.contains(QLatin1String("printing")) || state.contains(QLatin1String("imprime")) ? QStringLiteral("printing")
                                                                                                                  : QStringLiteral("idle");
        list.append(QVariantMap{{QStringLiteral("name"), m.captured(1)}, {QStringLiteral("status"), status}, {QStringLiteral("isDefault"), false}});
    }
    for (QVariant &v : list) {
        QVariantMap p = v.toMap();
        p.insert(QStringLiteral("isDefault"), p.value(QStringLiteral("name")).toString() == defaultName);
        v = p;
    }
    return list;
}

// « driverless » (cups-filters) : une URI ipp(s):// par imprimante réseau compatible sans pilote.
inline QVariantList parseDriverless(const QString &out)
{
    QVariantList list;
    QStringList seen;
    for (const QString &raw : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const QString uri = raw.trimmed();
        if (!(uri.startsWith(QLatin1String("ipp://")) || uri.startsWith(QLatin1String("ipps://"))))
            continue;
        // ipps://HP%20LaserJet%20M15w._ipps._tcp.local/ → « HP LaserJet M15w »
        QString host = uri.section(QLatin1String("://"), 1).section(QLatin1Char('/'), 0, 0);
        QString name = QUrl::fromPercentEncoding(host.toUtf8()).section(QLatin1String("._ipp"), 0, 0);
        if (seen.contains(name))
            continue;   // même imprimante en ipp et ipps : on garde la première (ipps en tête de liste)
        seen << name;
        list.append(QVariantMap{{QStringLiteral("name"), name}, {QStringLiteral("uri"), uri}});
    }
    return list;
}

// Nom de file d'impression CUPS valide à partir d'un nom affiché.
inline QString cupsQueueName(const QString &display)
{
    QString s;
    for (const QChar c : display) {
        if (c.isLetterOrNumber() && c.unicode() < 128)
            s += c;
        else if (!s.endsWith(QLatin1Char('_')))
            s += QLatin1Char('_');
    }
    while (s.endsWith(QLatin1Char('_')))
        s.chop(1);
    return s.isEmpty() ? QStringLiteral("Imprimante") : s.left(127);
}
