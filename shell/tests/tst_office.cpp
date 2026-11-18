// Compatibilité Microsoft Office : format par défaut de LibreOffice dans le profil utilisateur.
#include "officeparse.h"
#include <QtTest>

using namespace office;

class TestOffice : public QObject
{
    Q_OBJECT
private slots:
    void writeOnEmptyProfile()
    {
        const QString x = writeFormat(QString(), "msoffice");
        QVERIFY(x.startsWith("<?xml"));
        QVERIFY(x.contains("<value>MS Word 2007 XML</value>"));
        QVERIFY(x.contains("<value>Calc MS Excel 2007 XML</value>"));
        QVERIFY(x.contains("<value>Impress MS PowerPoint 2007 XML</value>"));
        QVERIFY(x.contains("WarnAlienFormat\" oor:op=\"fuse\"><value>false</value>"));
        QCOMPARE(readFormat(x), QString("msoffice"));
    }
    void switchKeepsOtherSettingsAndHasNoDuplicates()
    {
        QString x = emptyXcu();
        x.replace("</oor:items>", "<item oor:path=\"/org.openoffice.Office.Common/Misc\"><prop oor:name=\"FirstRun\" oor:op=\"fuse\"><value>false</value></prop></item>\n</oor:items>");
        x = writeFormat(x, "msoffice");
        x = writeFormat(x, "odf");
        QCOMPARE(readFormat(x), QString("odf"));
        QCOMPARE(x.count("ooSetupFactoryDefaultFilter"), 3);
        QCOMPARE(x.count("WarnAlienFormat"), 1);
        QVERIFY(x.contains("FirstRun"));                           // réglage étranger conservé
        QVERIFY(x.contains("<value>writer8</value>"));
    }
    void unknownWhenPartial()
    {
        QCOMPARE(readFormat(emptyXcu()), QString());
    }
};

QTEST_GUILESS_MAIN(TestOffice)
#include "tst_office.moc"
