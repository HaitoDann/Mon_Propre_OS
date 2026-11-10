#include <QTest>
#include "desktopentry.h"

class TestDesktopEntry : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void parsesLocalizedName()
    {
        const QByteArray file = "[Desktop Entry]\nName=Files\nName[fr]=Fichiers\nIcon=system-file-manager\n"
                                "Exec=dolphin %u\n[Desktop Action new]\nName=Other\n";
        const DesktopEntry e = parseDesktopEntry(file, QStringLiteral("fr_FR"));
        QVERIFY(e.valid);
        QCOMPARE(e.name, QStringLiteral("Fichiers"));
        QCOMPARE(e.icon, QStringLiteral("system-file-manager"));
        QCOMPARE(e.exec, QStringLiteral("dolphin %u"));
    }
    void ignoresOtherSections()
    {
        const DesktopEntry e = parseDesktopEntry("[Desktop Action x]\nName=Nope\n");
        QVERIFY(!e.valid);
    }
    void stripsFieldCodes()
    {
        QCOMPARE(desktopExecArguments(QStringLiteral("firefox-esr %u")), QStringList{QStringLiteral("firefox-esr")});
        QCOMPARE(desktopExecArguments(QStringLiteral("\"/opt/my app/run\" --flag %F")),
                 (QStringList{QStringLiteral("/opt/my app/run"), QStringLiteral("--flag")}));
        QCOMPARE(desktopExecArguments(QStringLiteral("printf 100%%")), (QStringList{QStringLiteral("printf"), QStringLiteral("100%")}));
    }
};

QTEST_GUILESS_MAIN(TestDesktopEntry)
#include "tst_desktopentry.moc"
