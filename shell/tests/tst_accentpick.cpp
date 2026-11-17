// Choix automatique de l'accent d'après le fond d'écran.
#include "accentpick.h"
#include <QPainter>
#include <QtTest>

using namespace accentpick;

class TestAccentPick : public QObject
{
    Q_OBJECT
    const QList<Candidate> palette{
        {"vert", QColor("#10DD8C")}, {"lagon", QColor("#2E9BFF")}, {"turquoise", QColor("#14C8C8")},
        {"citron", QColor("#C2E02E")}, {"ambre", QColor("#FFB21E")}, {"corail", QColor("#FF6B57")},
        {"framboise", QColor("#F0508C")}, {"graphite", QColor("#9AA09C")}};

    static QImage filled(const QColor &base, const QColor &spot = {}, double share = 0)
    {
        QImage img(200, 100, QImage::Format_RGB32);
        img.fill(base);
        if (spot.isValid()) {
            QPainter p(&img);
            p.fillRect(QRectF(0, 0, 200 * share, 100), spot);
        }
        return img;
    }

private slots:
    void solidColors_data()
    {
        QTest::addColumn<QColor>("color");
        QTest::addColumn<QString>("expected");
        QTest::newRow("ciel") << QColor("#3A86D8") << "lagon";
        QTest::newRow("forêt") << QColor("#2F8F4E") << "vert";
        QTest::newRow("coucher de soleil") << QColor("#E8663C") << "corail";
        QTest::newRow("sable doré") << QColor("#D9A441") << "ambre";
        QTest::newRow("lagune") << QColor("#1BA6A6") << "turquoise";
        QTest::newRow("fleurs roses") << QColor("#D9467E") << "framboise";
        QTest::newRow("prairie") << QColor("#9CC83A") << "citron";
    }
    void solidColors()
    {
        QFETCH(QColor, color);
        QFETCH(QString, expected);
        QCOMPARE(pick(filled(color), palette, "graphite"), expected);
    }
    void dullImageGivesNeutral()
    {
        QCOMPARE(pick(filled(QColor("#808080")), palette, "graphite"), QString("graphite"));
        QCOMPARE(pick(filled(QColor("#101010")), palette, "graphite"), QString("graphite"));
        QCOMPARE(pick(QImage(), palette, "graphite"), QString("graphite"));
    }
    void colourfulSpotWinsOverGreyBackground()
    {
        // Photo surtout grise avec un tiers de bleu vif : le bleu l'emporte.
        QCOMPARE(pick(filled(QColor("#9A9A9A"), QColor("#2070E0"), 0.33), palette, "graphite"), QString("lagon"));
    }
};

QTEST_GUILESS_MAIN(TestAccentPick)
#include "tst_accentpick.moc"
