#include <QtTest>
#include "diagparse.h"

static QString id(const char *s) { return QString::fromUtf8(s); }

class TestDiag : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void rules()
    {
        const QString log = QStringLiteral(
            "nov. 17 cupsd[812]: [Job 12] The printer is not responding.\n"
            "nov. 17 cupsd[812]: [Job 13] The printer is not responding.\n"
            "nov. 17 kernel: iwlwifi 0000:00:14.3: Direct firmware load for iwlwifi-so-a0-gf-a0-86.ucode failed with error -2\n"
            "nov. 17 NetworkManager[700]: <warn> device (wlp0s20f3): Activation: (wifi) disconnected during association, asking for new key\n"
            "nov. 17 NetworkManager[700]: secrets were required, but not provided\n"
            "nov. 17 systemd[1]: Failed to start bluetooth.service - Bluetooth service.\n"
            "nov. 17 kernel: wlp0s20f3: CTRL-EVENT-DISCONNECTED bssid=aa\n"
            "rien d'intéressant\n");
        const QVariantList d = diagnoseLog(log, id);
        QStringList ids;
        for (const QVariant &v : d) ids << v.toMap().value("id").toString();
        QVERIFY(ids.contains("printer-unreachable"));
        QVERIFY(ids.contains("firmware-missing"));
        QVERIFY(ids.contains("wifi-auth"));
        QVERIFY(ids.contains("service-failed"));
        QVERIFY(!ids.contains("wifi-drop"));          // une seule déconnexion : ignorée
        const QVariantMap printer = d[ids.indexOf("printer-unreachable")].toMap();
        QCOMPARE(printer.value("count").toInt(), 2);
        QCOMPARE(printer.value("action").toString(), QStringLiteral("page:printers"));
        QVERIFY(d[ids.indexOf("firmware-missing")].toMap().value("title").toString().contains("iwlwifi-so-a0-gf-a0-86.ucode"));
        QVERIFY(d[ids.indexOf("service-failed")].toMap().value("title").toString().contains("bluetooth.service - Bluetooth service"));
        QCOMPARE(d.first().toMap().value("severity").toInt(), 2);   // importants d'abord
    }
    void clean() { QVERIFY(diagnoseLog(QStringLiteral("tout va bien\n"), id).isEmpty()); }
    void df()
    {
        QCOMPARE(parseDfUsage(QStringLiteral("Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/nvme0n1p2 488245288 449185664 39059624 92% /\n")), 92);
        QCOMPARE(parseDfUsage(QString()), -1);
    }
};

QTEST_GUILESS_MAIN(TestDiag)
#include "tst_diag.moc"
