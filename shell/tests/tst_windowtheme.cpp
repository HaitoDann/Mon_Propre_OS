// Thème de fenêtre VinX (Aurorae) : fichiers complets, SVG valides, couleurs suivant l'accent.
#include "auroraetheme.h"
#include <QSvgRenderer>
#include <QtTest>

using namespace windowtheme;

class TestWindowTheme : public QObject
{
    Q_OBJECT
private slots:
    void filesAreComplete()
    {
        const auto files = themeFiles({});
        for (const char *name : {"metadata.desktop", "metadata.json", "VinXrc", "decoration.svg", "close.svg",
                                 "minimize.svg", "maximize.svg", "restore.svg"})
            QVERIFY2(files.contains(QString::fromLatin1(name)), name);
    }
    void decorationHasAllFrameElements()
    {
        QSvgRenderer svg(themeFiles({}).value("decoration.svg"));
        QVERIFY(svg.isValid());
        for (const QString &state : {QString(), QStringLiteral("inactive-")})
            for (const char *id : {"topleft", "top", "topright", "left", "right", "bottomleft", "bottom", "bottomright",
                                   "center", "maximized-top", "maximized-center"})
                QVERIFY2(svg.elementExists("decoration-" + state + QString::fromLatin1(id)), id);
    }
    void buttonsHaveAllStates()
    {
        for (const char *b : {"close.svg", "minimize.svg", "maximize.svg", "restore.svg"}) {
            QSvgRenderer svg(themeFiles({}).value(QString::fromLatin1(b)));
            QVERIFY2(svg.isValid(), b);
            for (const char *s : {"active", "hover", "pressed", "inactive", "deactivated", "hover-inactive"})
                QVERIFY2(svg.elementExists(QString::fromLatin1(s) + "-center"), s);
        }
    }
    void closeFollowsAccentAndOthersStayNeutral()
    {
        Colors c;
        c.accent = QColor("#2E9BFF");
        const auto files = themeFiles(c);
        QVERIFY(files.value("close.svg").contains("#2E9BFF"));
        QVERIFY(!files.value("minimize.svg").contains("#2E9BFF"));
        QVERIFY(files.value("close.svg").contains("#E5484D"));   // survol : rouge
    }
    void darkThemeChangesBarAndText()
    {
        Colors c;
        c.dark = true;
        const auto files = themeFiles(c);
        QVERIFY(files.value("decoration.svg").contains("#1A1C1B"));
        QVERIFY(files.value("VinXrc").contains("ActiveTextColor=236,236,234"));
        QVERIFY(themeFiles({}).value("VinXrc").contains("ActiveTextColor=20,20,20"));
    }
    void layoutGivesFortyPixelTitleBar()
    {
        const QByteArray rc = themeFiles({}).value("VinXrc");
        QVERIFY(rc.contains("TitleHeight=26"));
        QVERIFY(rc.contains("TitleEdgeTop=7"));
        QVERIFY(rc.contains("TitleEdgeBottom=7"));
    }
};

QTEST_GUILESS_MAIN(TestWindowTheme)
#include "tst_windowtheme.moc"
