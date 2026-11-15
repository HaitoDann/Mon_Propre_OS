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
    void sinks()
    {
        const QString status = QStringLiteral(
            "PipeWire 'pipewire-0' [1.4.2]\n"
            " └─ Clients:\n"
            "        33. WirePlumber\n"
            "\n"
            "Audio\n"
            " ├─ Devices:\n"
            " │      42. Built-in Audio                      [alsa]\n"
            " │  \n"
            " ├─ Sinks:\n"
            " │  *   47. Haut-parleurs intégrés              [vol: 0.40]\n"
            " │      52. HDMI / DisplayPort 1                [vol: 1.00 MUTED]\n"
            " │  \n"
            " ├─ Sources:\n"
            " │  *   48. Microphone intégré                  [vol: 0.50]\n"
            "\n"
            "Video\n"
            " ├─ Sinks:\n"
            " │      60. Ne doit pas apparaître\n");
        const QVariantList s = parseWpctlSinks(status);
        QCOMPARE(s.size(), 2);
        QCOMPARE(s[0].toMap().value("id").toInt(), 47);
        QCOMPARE(s[0].toMap().value("name").toString(), QStringLiteral("Haut-parleurs intégrés"));
        QVERIFY(s[0].toMap().value("isDefault").toBool());
        QCOMPARE(s[1].toMap().value("name").toString(), QStringLiteral("HDMI / DisplayPort 1"));
        QVERIFY(!s[1].toMap().value("isDefault").toBool());
    }
    void invalid()
    {
        QVERIFY(!parseWpctlVolume(QStringLiteral("Could not connect to PipeWire")).ok);
        QVERIFY(!parseWpctlVolume(QString()).ok);
    }
};

QTEST_GUILESS_MAIN(TestWpctl)
#include "tst_wpctl.moc"
