#pragma once

#include <QDir>
#include <QFileInfo>
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

// « appstreamcli search » : blocs « Clé: valeur » séparés par « --- ».
// → [{ id, name, summary, package, icon, homepage }] (seulement les composants avec paquet).
inline QVariantList parseAppstreamSearch(const QString &out)
{
    QVariantList list;
    QVariantMap cur;
    auto flush = [&] {
        if (!cur.value(QStringLiteral("package")).toString().isEmpty() && !cur.value(QStringLiteral("name")).toString().isEmpty())
            list.append(cur);
        cur.clear();
    };
    static const QRegularExpression kv(QStringLiteral("^(\\w[\\w ]*?):\\s*(.*)$"));
    for (const QString &raw : out.split(QLatin1Char('\n'))) {
        const QString line = raw.trimmed();
        if (line == QLatin1String("---")) { flush(); continue; }
        const auto m = kv.match(line);
        if (!m.hasMatch())
            continue;
        const QString k = m.captured(1).toLower(), v = m.captured(2).trimmed();
        if (k == QLatin1String("identifier")) cur.insert(QStringLiteral("id"), v.section(QLatin1Char(' '), 0, 0));
        else if (k == QLatin1String("name")) cur.insert(QStringLiteral("name"), v);
        else if (k == QLatin1String("summary")) cur.insert(QStringLiteral("summary"), v);
        else if (k == QLatin1String("package")) cur.insert(QStringLiteral("package"), v);
        else if (k == QLatin1String("homepage")) cur.insert(QStringLiteral("homepage"), v);
        else if (k == QLatin1String("icon")) {
            // Icône en cache AppStream (« cached: 64x64/gimp_org.gimp.GIMP.png ») : chemin relatif gardé
            // pour retrouver le logo d'un logiciel non installé (resolveAppstreamIcon).
            if (v.startsWith(QLatin1String("cached:")))
                cur.insert(QStringLiteral("iconCached"), v.mid(7).trimmed());
            // « firefox-esr.png » ou « cached: 64x64/firefox-esr_firefox-esr.png » → nom de thème probable.
            QString icon = v.section(QLatin1Char(' '), -1).section(QLatin1Char('/'), -1);
            if (icon.endsWith(QLatin1String(".png")) || icon.endsWith(QLatin1String(".svg")) || icon.endsWith(QLatin1String(".xpm")))
                icon.chop(4);
            if (icon.contains(QLatin1Char('_')))
                icon = icon.section(QLatin1Char('_'), 1);
            cur.insert(QStringLiteral("icon"), icon);
        }
    }
    flush();
    // Un composant par paquet.
    QVariantList out2;
    QStringList seen;
    for (const QVariant &v : list) {
        const QString pkg = v.toMap().value(QStringLiteral("package")).toString();
        if (!seen.contains(pkg)) { seen << pkg; out2.append(v); }
    }
    return out2;
}

// « apt-cache search --names-only » : « paquet - description courte ».
inline QVariantList parseAptSearch(const QString &out)
{
    QVariantList list;
    for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const int sep = line.indexOf(QLatin1String(" - "));
        if (sep <= 0)
            continue;
        const QString pkg = line.left(sep).trimmed();
        list.append(QVariantMap{{QStringLiteral("id"), pkg}, {QStringLiteral("name"), pkg}, {QStringLiteral("package"), pkg},
                                {QStringLiteral("summary"), line.mid(sep + 3).trimmed()}, {QStringLiteral("icon"), QString()}});
    }
    return list;
}

// « apt-cache show PAQUET » : version, taille, site, description longue (en français si disponible).
inline QVariantMap parseAptShow(const QString &out)
{
    QVariantMap m;
    QString descKey, desc;
    bool inDesc = false;
    for (const QString &line : out.split(QLatin1Char('\n'))) {
        if (line.isEmpty()) {
            if (!m.isEmpty()) break;   // premier enregistrement seulement
            continue;
        }
        if (inDesc && line.startsWith(QLatin1Char(' '))) {
            const QString t = line.trimmed();
            desc += (t == QLatin1String(".") ? QStringLiteral("\n\n") : t + QLatin1Char(' '));
            continue;
        }
        inDesc = false;
        const QString key = line.section(QLatin1Char(':'), 0, 0), val = line.section(QLatin1Char(':'), 1).trimmed();
        if (key == QLatin1String("Version")) m.insert(QStringLiteral("version"), val);
        else if (key == QLatin1String("Installed-Size")) m.insert(QStringLiteral("installedSize"), val.toLongLong() * 1024);
        else if (key == QLatin1String("Homepage")) m.insert(QStringLiteral("homepage"), val);
        else if (key == QLatin1String("Section")) m.insert(QStringLiteral("section"), val);
        else if (key.startsWith(QLatin1String("Description")) && (descKey.isEmpty() || key == QLatin1String("Description-fr"))) {
            descKey = key;
            m.insert(QStringLiteral("summary"), val);
            desc.clear();
            inDesc = true;
        }
    }
    m.insert(QStringLiteral("description"), desc.trimmed());
    return m;
}

// Ligne de progression de « pkcon --plain » (« Percentage:\t42 ») ou de flatpak (« 42% ») : -1 sinon.
inline int parseProgressLine(const QString &line)
{
    static const QRegularExpression pk(QStringLiteral("^Percentage:\\s*(\\d+)"));
    static const QRegularExpression pct(QStringLiteral("(\\d{1,3})%"));
    auto m = pk.match(line.trimmed());
    if (m.hasMatch()) return qMin(100, m.captured(1).toInt());
    QRegularExpressionMatchIterator it = pct.globalMatch(line);
    int last = -1;
    while (it.hasNext()) last = qMin(100, it.next().captured(1).toInt());
    return last;
}

// Fichier d'icône AppStream en cache (« 64x64/gimp_org.gimp.GIMP.png ») : cherché dans les dossiers
// de cache d'AppStream (racine/<origine>/<taille>/<fichier>), la plus grande taille d'abord.
inline QString resolveAppstreamIcon(const QString &cached, const QStringList &roots)
{
    if (cached.isEmpty())
        return {};
    const QString file = cached.section(QLatin1Char('/'), -1);
    const QString size = cached.contains(QLatin1Char('/')) ? cached.section(QLatin1Char('/'), 0, 0) : QStringLiteral("64x64");
    for (const QString &sz : {QStringLiteral("128x128"), size, QStringLiteral("64x64")})
        for (const QString &root : roots) {
            const QDir dir(root);
            for (const QString &origin : dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
                const QString path = root + QLatin1Char('/') + origin + QLatin1Char('/') + sz + QLatin1Char('/') + file;
                if (QFileInfo::exists(path))
                    return path;
            }
        }
    return {};
}

inline QStringList appstreamIconRoots()
{
    return {QStringLiteral("/var/cache/swcatalog/icons"), QStringLiteral("/usr/share/swcatalog/icons"),
            QStringLiteral("/var/lib/swcatalog/icons"), QStringLiteral("/var/cache/app-info/icons"),
            QStringLiteral("/var/lib/app-info/icons"), QStringLiteral("/usr/share/app-info/icons")};
}

// « lpoptions -p IMPRIMANTE » : « copies=1 media=iso_a4_210x297mm sides=one-sided job-sheets='none none' … »
// → { media: "a4" | "letter" | …, sides, color: "color" | "monochrome" } (valeurs CUPS normalisées).
inline QVariantMap parseLpoptions(const QString &out)
{
    QVariantMap m;
    static const QRegularExpression tok(QStringLiteral("([\\w-]+)=('[^']*'|\\S+)"));
    auto it = tok.globalMatch(out);
    while (it.hasNext()) {
        const auto t = it.next();
        QString v = t.captured(2);
        if (v.startsWith(QLatin1Char('\''))) v = v.mid(1, v.size() - 2);
        m.insert(t.captured(1), v);
    }
    QVariantMap r;
    const QString media = m.value(QStringLiteral("media")).toString().toLower();
    r.insert(QStringLiteral("media"), media.contains(QLatin1String("letter")) ? QStringLiteral("letter")
                                      : media.contains(QLatin1String("a4")) || media.isEmpty() ? QStringLiteral("a4") : media);
    r.insert(QStringLiteral("sides"), m.value(QStringLiteral("sides"), QStringLiteral("one-sided")));
    const QString color = m.value(QStringLiteral("print-color-mode"), m.value(QStringLiteral("ColorModel"))).toString().toLower();
    r.insert(QStringLiteral("color"), color.contains(QLatin1String("mono")) || color.contains(QLatin1String("gray")) ? QStringLiteral("monochrome") : QStringLiteral("color"));
    return r;
}

// « nmcli -t -f NAME,TYPE,ACTIVE,DEVICE connection show » → VPN : [{ name, kind, active }]
inline QVariantList parseNmcliVpns(const QString &out)
{
    QVariantList list;
    for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const QStringList f = splitNmcliTerse(line);
        if (f.size() < 3)
            continue;
        const QString type = f.at(1);
        if (type != QLatin1String("vpn") && type != QLatin1String("wireguard"))
            continue;
        list.append(QVariantMap{{QStringLiteral("name"), f.at(0)},
                                {QStringLiteral("kind"), type == QLatin1String("wireguard") ? QStringLiteral("WireGuard") : QStringLiteral("VPN")},
                                {QStringLiteral("active"), f.at(2) == QLatin1String("yes")}});
    }
    return list;
}

// « nmcli -t -f ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns connection show NOM »
// → { manual, address, prefix, gateway, dns }
inline QVariantMap parseNmcliIpv4(const QString &out)
{
    QVariantMap m{{QStringLiteral("manual"), false}};
    for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const QString key = line.section(QLatin1Char(':'), 0, 0), value = line.section(QLatin1Char(':'), 1).trimmed();
        if (key == QLatin1String("ipv4.method")) m.insert(QStringLiteral("manual"), value == QLatin1String("manual"));
        else if (key == QLatin1String("ipv4.addresses")) {
            const QString first = value.section(QLatin1Char(','), 0, 0).trimmed();
            m.insert(QStringLiteral("address"), first.section(QLatin1Char('/'), 0, 0));
            m.insert(QStringLiteral("prefix"), first.contains(QLatin1Char('/')) ? first.section(QLatin1Char('/'), 1).toInt() : 24);
        }
        else if (key == QLatin1String("ipv4.gateway")) m.insert(QStringLiteral("gateway"), value == QLatin1String("--") ? QString() : value);
        else if (key == QLatin1String("ipv4.dns")) m.insert(QStringLiteral("dns"), value == QLatin1String("--") ? QString() : value.section(QLatin1Char(','), 0, 0));
    }
    return m;
}
