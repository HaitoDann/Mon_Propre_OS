#include <QTemporaryDir>
#include <QtTest>
#include "sysparse.h"

class TestSysParse : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void nmcliEscapes()
    {
        QCOMPARE(splitNmcliTerse(QStringLiteral("*:Box\\:5G:80:WPA2")), QStringList({"*", "Box:5G", "80", "WPA2"}));
        QCOMPARE(splitNmcliTerse(QStringLiteral(" :a\\\\b::")), QStringList({" ", "a\\b", "", ""}));
    }
    void wifiList()
    {
        const QString out = QStringLiteral(
            " :Voisin:40:WPA2\n"
            "*:Maison:62:WPA2\n"
            " :Maison:75:WPA2\n"
            " :Café\\: invités:55:\n"
            " ::90:WPA2\n"
            " :Voisin:58:WPA2\n");
        const QVariantList l = parseNmcliWifi(out);
        QCOMPARE(l.size(), 3);
        QCOMPARE(l[0].toMap().value("ssid").toString(), QStringLiteral("Maison"));     // actif en premier
        QVERIFY(l[0].toMap().value("active").toBool());
        QCOMPARE(l[1].toMap().value("ssid").toString(), QStringLiteral("Voisin"));
        QCOMPARE(l[1].toMap().value("signal").toInt(), 58);                              // le plus fort
        QCOMPARE(l[2].toMap().value("ssid").toString(), QStringLiteral("Café: invités"));
        QVERIFY(!l[2].toMap().value("secure").toBool());
    }
    void knownWifi()
    {
        QCOMPARE(parseNmcliKnownWifi(QStringLiteral("Maison:802-11-wireless\nFilaire 1:802-3-ethernet\nBureau\\:2:802-11-wireless\n")),
                 QStringList({"Maison", "Bureau:2"}));
    }
    void lspci()
    {
        const QVariantList d = parseLspci(QStringLiteral(
            "00:02.0 \"VGA compatible controller [0300]\" \"Intel Corporation [8086]\" \"Alder Lake-P GT2 [46a6]\" -r0c \"Lenovo [17aa]\" \"Device [3b2a]\"\n"
            "01:00.0 \"3D controller [0302]\" \"NVIDIA Corporation [10de]\" \"GA107M [25a2]\" -ra1 \"Lenovo [17aa]\" \"Device [3b2a]\"\n"));
        QCOMPARE(d.size(), 2);
        QCOMPARE(d[0].toMap().value("vendor").toString(), QStringLiteral("Intel Corporation"));
        QCOMPARE(d[1].toMap().value("vendorId").toString(), QStringLiteral("10de"));
        QCOMPARE(d[1].toMap().value("classId").toString(), QStringLiteral("0302"));
        QCOMPARE(d[1].toMap().value("name").toString(), QStringLiteral("GA107M"));
    }
    void lpstat()
    {
        const QVariantList p = parseLpstat(QStringLiteral(
            "printer HP_M15w is idle.  enabled since Mon 16 Nov 2026\n"
            "printer Bureau now printing Bureau-12.  enabled since …\n"
            "system default destination: Bureau\n"));
        QCOMPARE(p.size(), 2);
        QCOMPARE(p[0].toMap().value("status").toString(), QStringLiteral("idle"));
        QCOMPARE(p[1].toMap().value("status").toString(), QStringLiteral("printing"));
        QVERIFY(p[1].toMap().value("isDefault").toBool());
    }
    void driverless()
    {
        const QVariantList p = parseDriverless(QStringLiteral(
            "ipps://HP%20LaserJet%20M15w%20%5B1A2B3C%5D._ipps._tcp.local/\n"
            "ipp://HP%20LaserJet%20M15w%20%5B1A2B3C%5D._ipp._tcp.local/\n"
            "bruit\n"));
        QCOMPARE(p.size(), 1);
        QCOMPARE(p[0].toMap().value("name").toString(), QStringLiteral("HP LaserJet M15w [1A2B3C]"));
        QVERIFY(p[0].toMap().value("uri").toString().startsWith("ipps://"));
        QCOMPARE(cupsQueueName(QStringLiteral("HP LaserJet M15w [1A2B3C]")), QStringLiteral("HP_LaserJet_M15w_1A2B3C"));
        QCOMPARE(cupsQueueName(QStringLiteral("é")), QStringLiteral("Imprimante"));
    }
    void appstream()
    {
        const QVariantList l = parseAppstreamSearch(QStringLiteral(
            "Identifier: org.gimp.GIMP [desktop-application]\nName: GNU Image Manipulation Program\nSummary: Create images and edit photographs\n"
            "Package: gimp\nHomepage: https://www.gimp.org/\nIcon: cached: 64x64/gimp_org.gimp.GIMP.png\n---\n"
            "Identifier: gimp-help [addon]\nName: Aide\nSummary: x\n---\n"
            "Identifier: org.inkscape.Inkscape [desktop-application]\nName: Inkscape\nSummary: Vector Graphics Editor\nPackage: inkscape\nIcon: org.inkscape.Inkscape.png\n"));
        QCOMPARE(l.size(), 2);
        QCOMPARE(l[0].toMap().value("package").toString(), QStringLiteral("gimp"));
        QCOMPARE(l[0].toMap().value("icon").toString(), QStringLiteral("org.gimp.GIMP"));
        QCOMPARE(l[1].toMap().value("icon").toString(), QStringLiteral("org.inkscape.Inkscape"));
        QCOMPARE(l[0].toMap().value("iconCached").toString(), QStringLiteral("64x64/gimp_org.gimp.GIMP.png"));
        QVERIFY(!l[1].toMap().contains("iconCached"));
    }
    void nmcliVpnAndIp()
    {
        const QVariantList v = parseNmcliVpns(QStringLiteral(
            "Livebox-4A2C:802-11-wireless:yes:wlp2s0\nBureau\\: siège:vpn:no:\nwg0:wireguard:yes:wg0\nFilaire:802-3-ethernet:no:\n"));
        QCOMPARE(v.size(), 2);
        QCOMPARE(v[0].toMap().value("name").toString(), QString("Bureau: siège"));
        QCOMPARE(v[0].toMap().value("active").toBool(), false);
        QCOMPARE(v[1].toMap().value("kind").toString(), QString("WireGuard"));
        const QVariantMap ip = parseNmcliIpv4(QStringLiteral("ipv4.method:manual\nipv4.addresses:192.168.1.50/24\nipv4.gateway:192.168.1.1\nipv4.dns:1.1.1.1,9.9.9.9\n"));
        QCOMPARE(ip.value("manual").toBool(), true);
        QCOMPARE(ip.value("address").toString(), QString("192.168.1.50"));
        QCOMPARE(ip.value("prefix").toInt(), 24);
        QCOMPARE(ip.value("gateway").toString(), QString("192.168.1.1"));
        QCOMPARE(ip.value("dns").toString(), QString("1.1.1.1"));
        QCOMPARE(parseNmcliIpv4(QStringLiteral("ipv4.method:auto\nipv4.gateway:--\n")).value("manual").toBool(), false);
    }
    void lpoptions()
    {
        const QVariantMap o = parseLpoptions(QStringLiteral("copies=1 device-uri=ipp://x job-sheets='none none' media=iso_a4_210x297mm sides=two-sided-long-edge print-color-mode=monochrome"));
        QCOMPARE(o.value("media").toString(), QString("a4"));
        QCOMPARE(o.value("sides").toString(), QString("two-sided-long-edge"));
        QCOMPARE(o.value("color").toString(), QString("monochrome"));
        const QVariantMap d = parseLpoptions(QStringLiteral("media=na_letter_8.5x11in"));
        QCOMPARE(d.value("media").toString(), QString("letter"));
        QCOMPARE(d.value("sides").toString(), QString("one-sided"));
        QCOMPARE(d.value("color").toString(), QString("color"));
    }
    void appstreamIconCache()
    {
        QTemporaryDir root;
        QDir(root.path()).mkpath("debian-trixie-main/64x64");
        QDir(root.path()).mkpath("debian-trixie-main/128x128");
        QFile small(root.path() + "/debian-trixie-main/64x64/gimp_org.gimp.GIMP.png");
        QVERIFY(small.open(QIODevice::WriteOnly));
        small.close();
        QCOMPARE(resolveAppstreamIcon("64x64/gimp_org.gimp.GIMP.png", {root.path()}), small.fileName());
        QFile big(root.path() + "/debian-trixie-main/128x128/gimp_org.gimp.GIMP.png");   // la plus grande d'abord
        QVERIFY(big.open(QIODevice::WriteOnly));
        big.close();
        QCOMPARE(resolveAppstreamIcon("64x64/gimp_org.gimp.GIMP.png", {"/nulle/part", root.path()}), big.fileName());
        QCOMPARE(resolveAppstreamIcon("64x64/absent.png", {root.path()}), QString());
        // Sans « cached: » : le fichier du cache s'appelle « paquet_id.png ».
        const QVariantMap gimp{{"package", "gimp"}, {"icon", "org.gimp.GIMP"}};
        QCOMPARE(appstreamIconFor(gimp, {root.path()}), big.fileName());
        QCOMPARE(appstreamIconFor(QVariantMap{{"package", "x"}, {"icon", "absent"}}, {root.path()}), QString());
    }
    void aptSearchShow()
    {
        const QVariantList s = parseAptSearch(QStringLiteral("htop - interactive processes viewer\nbtop - modern monitor - with dashes\n"));
        QCOMPARE(s.size(), 2);
        QCOMPARE(s[1].toMap().value("summary").toString(), QStringLiteral("modern monitor - with dashes"));
        const QVariantMap d = parseAptShow(QStringLiteral(
            "Package: htop\nVersion: 3.4.0-2\nInstalled-Size: 450\nHomepage: https://htop.dev/\nDescription-en: interactive processes viewer\n"
            " Htop is an ncursed-based process viewer.\n .\n It is aimed to be better.\nDescription-fr: visualiseur interactif\n Htop affiche les processus.\n\nPackage: htop\nVersion: 0\n"));
        QCOMPARE(d.value("version").toString(), QStringLiteral("3.4.0-2"));
        QCOMPARE(d.value("installedSize").toLongLong(), 450 * 1024);
        QCOMPARE(d.value("summary").toString(), QStringLiteral("visualiseur interactif"));
        QCOMPARE(d.value("description").toString(), QStringLiteral("Htop affiche les processus."));
    }
    void progress()
    {
        QCOMPARE(parseProgressLine(QStringLiteral("Percentage:\t42")), 42);
        QCOMPARE(parseProgressLine(QStringLiteral("Updating 2/5… ████  73%  1.2 MB/s")), 73);
        QCOMPARE(parseProgressLine(QStringLiteral("Status:\tDownloading")), -1);
    }
};

QTEST_GUILESS_MAIN(TestSysParse)
#include "tst_sysparse.moc"
