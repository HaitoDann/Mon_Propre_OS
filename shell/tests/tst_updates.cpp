#include <QtTest>
#include "updateparse.h"

class TestUpdates : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void apt()
    {
        const QString out = QStringLiteral(
            "Listing... Done\n"
            "firefox-esr/stable-security 128.5.0esr-1~deb13u1 amd64 [upgradable from: 128.4.0esr-1~deb13u1]\n"
            "libc6/stable 2.41-12 amd64 [pouvant être mis à jour depuis : 2.41-11]\n"
            "\n");
        const QVariantList l = parseAptUpgradable(out);
        QCOMPARE(l.size(), 2);
        QCOMPARE(l[0].toMap().value("name").toString(), QStringLiteral("firefox-esr"));
        QCOMPARE(l[0].toMap().value("version").toString(), QStringLiteral("128.5.0esr-1~deb13u1"));
        QCOMPARE(l[0].toMap().value("from").toString(), QStringLiteral("128.4.0esr-1~deb13u1"));
        QCOMPARE(l[1].toMap().value("from").toString(), QStringLiteral("2.41-11"));
    }
    void flatpak()
    {
        const QString out = QStringLiteral(
            "Application ID\tName\tVersion\n"
            "org.gimp.GIMP\tGIMP\t3.0.4\n"
            "org.kde.krita\tKrita\t\n"
            "incomplet\n");
        const QVariantList l = parseFlatpakColumns(out, {"id", "name", "version"});
        QCOMPARE(l.size(), 2);
        QCOMPARE(l[0].toMap().value("name").toString(), QStringLiteral("GIMP"));
        QCOMPARE(l[1].toMap().value("version").toString(), QString());
    }
    void empty() { QVERIFY(parseAptUpgradable({}).isEmpty()); QVERIFY(parseFlatpakColumns({}, {"id"}).isEmpty()); }
    void aptHistory()
    {
        const QString log = QStringLiteral(
            "\nStart-Date: 2026-11-16  10:02:11\nCommandline: apt-get install vlc\n"
            "Install: vlc:amd64 (3.0.21-1), libvlc5:amd64 (3.0.21-1, automatic)\nEnd-Date: 2026-11-16  10:02:30\n\n"
            "Start-Date: 2026-11-17  21:37:41\nCommandline: apt-get install -y ./vinx-shell.deb\n"
            "Upgrade: vinx-shell:amd64 (0.17.0, 0.18.0), firefox-esr:amd64 (128.4.0esr-1, 128.5.0esr-1)\n"
            "Remove: konsole:amd64 (4:24.12.3-1)\nEnd-Date: 2026-11-17  21:37:44\n\n"
            "Start-Date: 2026-11-17  22:00:00\nCommandline: apt-get update\nEnd-Date: 2026-11-17  22:00:01\n");
        const QVariantList h = parseAptHistory(log);
        QCOMPARE(h.size(), 2);                                  // l'opération sans paquet est ignorée
        const QVariantMap last = h.first().toMap();               // la plus récente d'abord
        QCOMPARE(last.value("date").toString(), QString("2026-11-17 21:37"));
        QCOMPARE(last.value("upgraded").toInt(), 2);
        QCOMPARE(last.value("removed").toInt(), 1);
        QCOMPARE(last.value("packages").toString(), QString("vinx-shell, firefox-esr, konsole"));
        QCOMPARE(h.last().toMap().value("installed").toInt(), 2);
    }
    void vinxRelease()
    {
        QCOMPARE(parseVinxRelease("VINX_VERSION=\"0.17.1\"\n"), QString("0.17.1"));
        QCOMPARE(parseVinxRelease("X=1\nVINX_VERSION=0.18\n"), QString("0.18"));
        QCOMPARE(parseVinxRelease(""), QString());
    }
};

QTEST_GUILESS_MAIN(TestUpdates)
#include "tst_updates.moc"
