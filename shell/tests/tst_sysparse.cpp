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
};

QTEST_GUILESS_MAIN(TestSysParse)
#include "tst_sysparse.moc"
