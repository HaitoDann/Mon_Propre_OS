// Terminal VinX : schémas de couleurs et lecture des préférences VinX.
#include "termtheme.h"
#include <QTemporaryDir>
#include <QtTest>

class TestTermTheme : public QObject
{
    Q_OBJECT
private slots:
    void schemeHasAllSections()
    {
        for (bool dark : {false, true}) {
            const QString s = termtheme::colorScheme(dark);
            for (const char *sec : {"[Background]", "[Foreground]", "[Color0]", "[Color7Intense]", "[General]"})
                QVERIFY2(s.contains(QString::fromLatin1(sec)), sec);
        }
        QVERIFY(termtheme::colorScheme(true).contains("Color=18,20,19") || termtheme::colorScheme(true).contains("Color=26,28,27"));
        QVERIFY(termtheme::colorScheme(false).contains("[Foreground]\nColor=20,20,20"));
    }
    void readsVinxPreferences()
    {
        QTemporaryDir dir;
        const QString ini = dir.filePath("shell.ini");
        QCOMPARE(termtheme::readAppearance(ini).dark, false);                     // pas de fichier : défauts
        QCOMPARE(termtheme::readAppearance(ini).accent, QString("#10DD8C"));
        {
            QSettings s(ini, QSettings::IniFormat);
            s.setValue("appearance/dark", true);
            s.setValue("appearance/accent", "lagon");
        }
        QCOMPARE(termtheme::readAppearance(ini).dark, true);
        QCOMPARE(termtheme::readAppearance(ini).accent, QString("#2E9BFF"));
        {
            QSettings s(ini, QSettings::IniFormat);
            s.setValue("appearance/accent", "auto");
            s.setValue("appearance/resolvedAccent", "corail");
        }
        QCOMPARE(termtheme::readAppearance(ini).accent, QString("#FF6B57"));
    }
};

QTEST_GUILESS_MAIN(TestTermTheme)
#include "tst_termtheme.moc"
