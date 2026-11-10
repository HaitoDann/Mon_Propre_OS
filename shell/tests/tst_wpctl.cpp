#include <QTest>
#include "wpctl.h"

class TestWpctl : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void normal()
    {
        const auto v = parseWpctlVolume(QStringLiteral("Volume: 0.60\n"));
        QVERIFY(v.ok);
        QCOMPARE(v.volume, 0.60);
        QVERIFY(!v.muted);
    }
    void muted()
    {
        const auto v = parseWpctlVolume(QStringLiteral("Volume: 0.35 [MUTED]\n"));
        QVERIFY(v.ok);
        QCOMPARE(v.volume, 0.35);
        QVERIFY(v.muted);
    }
    void amplified()
    {
        QCOMPARE(parseWpctlVolume(QStringLiteral("Volume: 1.20")).volume, 1.20);
    }
    void invalid()
    {
        QVERIFY(!parseWpctlVolume(QStringLiteral("Could not connect to PipeWire")).ok);
        QVERIFY(!parseWpctlVolume(QString()).ok);
    }
};

QTEST_GUILESS_MAIN(TestWpctl)
#include "tst_wpctl.moc"
