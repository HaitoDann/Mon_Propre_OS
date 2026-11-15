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
};

QTEST_GUILESS_MAIN(TestUpdates)
#include "tst_updates.moc"
