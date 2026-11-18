#include <QtTest>

#include "captureutil.h"

// Capture d'écran (ADR 0036) : image brute de KWin, nom de fichier, annotations.
class TestScreenshot : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void imageFromRaw()
    {
        QImage source(4, 3, QImage::Format_ARGB32);
        source.fill(QColor(10, 20, 30));
        source.setPixelColor(3, 2, Qt::red);
        const QByteArray data(reinterpret_cast<const char *>(source.constBits()), source.sizeInBytes());
        const QVariantMap meta{{QStringLiteral("type"), QStringLiteral("raw")}, {QStringLiteral("width"), 4u}, {QStringLiteral("height"), 3u},
                               {QStringLiteral("stride"), uint(source.bytesPerLine())}, {QStringLiteral("format"), uint(QImage::Format_ARGB32)},
                               {QStringLiteral("scale"), 2.0}};
        const QImage image = Capture::imageFromRaw(data, meta);
        QCOMPARE(image.size(), QSize(4, 3));
        QCOMPARE(image.pixelColor(3, 2), QColor(Qt::red));
        QCOMPARE(image.devicePixelRatio(), 2.0);
        // Données tronquées ou format inconnu : pas d'image plutôt qu'une lecture hors du tampon.
        QVERIFY(Capture::imageFromRaw(data.left(10), meta).isNull());
        QVariantMap bad = meta;
        bad[QStringLiteral("format")] = 9999u;
        QVERIFY(Capture::imageFromRaw(data, bad).isNull());
    }

    void fileName()
    {
        const QDateTime when(QDate(2026, 11, 18), QTime(10, 42, 15));
        QCOMPARE(Capture::fileName(when, QStringLiteral("Capture du %1 à %2")), QStringLiteral("Capture du 2026-11-18 à 10.42.15.png"));
    }

    void render()
    {
        QImage source(400, 300, QImage::Format_ARGB32);
        source.fill(Qt::white);
        for (int x = 0; x < 400; x += 2)   // rayures : le flou doit les effacer
            for (int y = 200; y < 300; ++y)
                source.setPixelColor(x, y, Qt::black);
        const QImage plain = Capture::render(source, {});
        QCOMPARE(plain.pixelColor(10, 10), QColor(Qt::white));

        QList<Capture::Shape> shapes;
        Capture::Shape frame;
        frame.kind = Capture::Shape::Frame;
        frame.from = QPointF(50, 50);
        frame.to = QPointF(150, 120);
        shapes << frame;
        Capture::Shape blur;
        blur.kind = Capture::Shape::Blur;
        blur.from = QPointF(0, 200);
        blur.to = QPointF(400, 300);
        shapes << blur;
        Capture::Shape mark = Capture::shapeFromMap({{QStringLiteral("kind"), QStringLiteral("highlight")}, {QStringLiteral("x1"), 200}, {QStringLiteral("y1"), 20},
                                                     {QStringLiteral("x2"), 300}, {QStringLiteral("y2"), 60}, {QStringLiteral("color"), QStringLiteral("#FEBC2E")}});
        QCOMPARE(mark.kind, Capture::Shape::Highlight);
        shapes << mark;
        const QImage out = Capture::render(source, shapes);
        QCOMPARE(out.size(), source.size());
        QCOMPARE(out.pixelColor(50, 85).red(), 255);           // trait du cadre (rouge)
        QVERIFY(out.pixelColor(50, 85).green() < 150);
        QCOMPARE(out.pixelColor(100, 85), QColor(Qt::white));   // intérieur du cadre intact
        const QColor striped = out.pixelColor(201, 250);        // rayure noire floutée → gris
        QVERIFY(striped.red() > 40 && striped.red() < 220);
        const QColor yellow = out.pixelColor(250, 40);          // surlignage : jaune translucide
        QVERIFY(yellow.blue() < 200 && yellow.red() > 200);
        QCOMPARE(source.pixelColor(200, 250), QColor(Qt::black)); // l'original n'est pas modifié
    }
};

QTEST_GUILESS_MAIN(TestScreenshot)
#include "tst_screenshot.moc"
