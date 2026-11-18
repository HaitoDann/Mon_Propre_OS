#include <QImage>
#include <QTemporaryDir>
#include <QtEndian>
#include <QtTest>

#include "exif.h"
#include "photo.h"
#include "viewer.h"

// Visionneur d'images (ADR 0038) : EXIF, retouches, dossier, copie modifiée.
class TestViewer : public QObject
{
    Q_OBJECT

    // Petit bloc TIFF petit-boutiste : IFD0 (marque, modèle, orientation, renvoi EXIF) + IFD EXIF.
    static QByteArray tiff()
    {
        QByteArray t("II*\0\x08\0\0\0", 8);
        auto u16 = [&t](quint16 v) { char b[2]; qToLittleEndian(v, b); t.append(b, 2); };
        auto u32 = [&t](quint32 v) { char b[4]; qToLittleEndian(v, b); t.append(b, 4); };
        auto entry = [&](quint16 tag, quint16 type, quint32 count, quint32 value) { u16(tag); u16(type); u32(count); u32(value); };
        // IFD0 à 8 : 4 entrées → données à 8 + 2 + 48 + 4 = 62
        u16(4);
        entry(0x010F, 2, 6, 62);        // « Canon\0 »
        entry(0x0110, 2, 13, 68);       // « Canon EOS 80D\0 » (13 avec le zéro)
        entry(0x0112, 3, 1, 6);         // orientation 6
        entry(0x8769, 4, 1, 82);
        u32(0);
        t.append("Canon\0", 6);
        t.append("Canon EOS 80D", 13);
        t.append('\0');                 // alignement → 82
        // IFD EXIF à 82 : 3 entrées → données à 82 + 2 + 36 + 4 = 124
        u16(3);
        entry(0x9003, 2, 20, 124);
        entry(0x829A, 5, 1, 144);
        entry(0x8827, 3, 1, 400);
        u32(0);
        t.append("2026:08:14 18:42:07\0", 20);
        u32(1); u32(250);               // 1/250 s
        return t;
    }

private Q_SLOTS:
    void exif()
    {
        const Exif::Info info = Exif::parse(tiff());
        QVERIFY(info.valid);
        QCOMPARE(info.make, QString());   // répétée dans le modèle : retirée
        QCOMPARE(info.model, QStringLiteral("Canon EOS 80D"));
        QCOMPARE(info.orientation, 6);
        QCOMPARE(info.taken, QDateTime(QDate(2026, 8, 14), QTime(18, 42, 7)));
        QCOMPARE(Exif::exposureText(info.exposure), QStringLiteral("1/250 s"));
        QCOMPARE(info.iso, 400);
        // Dans un JPEG : segment APP1 « Exif ».
        QByteArray jpeg("\xFF\xD8", 2);
        const QByteArray payload = QByteArray("Exif\0\0", 6) + tiff();
        jpeg += QByteArray("\xFF\xE1", 2);
        char len[2];
        qToBigEndian<quint16>(quint16(payload.size() + 2), len);
        jpeg += QByteArray(len, 2) + payload + QByteArray("\xFF\xDA", 2);
        QCOMPARE(Exif::jpegExifBlock(jpeg), tiff());
        QVERIFY(!Exif::parse("pas un tiff").valid);
        QVERIFY(Exif::jpegExifBlock("pas un jpeg").isEmpty());
    }

    void edits()
    {
        QImage source(400, 200, QImage::Format_ARGB32);
        source.fill(QColor(100, 100, 100));
        source.setPixelColor(0, 0, Qt::red);   // coin haut gauche
        Photo::Edits e;
        QVERIFY(e.isIdentity());
        e.quarterTurns = 1;                     // quart de tour horaire : le coin passe en haut à droite
        QImage out = Photo::apply(source, e);
        QCOMPARE(out.size(), QSize(200, 400));
        QCOMPARE(out.pixelColor(199, 0), QColor(Qt::red));
        e.crop = QRectF(0.5, 0, 0.5, 0.5);      // quart haut droit de l'image pivotée
        out = Photo::apply(source, e);
        QCOMPARE(out.size(), QSize(100, 200));
        QCOMPARE(out.pixelColor(99, 0), QColor(Qt::red));
        e = {};
        e.brightness = 50;
        QVERIFY(Photo::apply(source, e).pixelColor(10, 10).red() > 150);
        e = {};
        e.contrast = -100;                      // contraste minimal : vers le gris moyen
        QVERIFY(qAbs(Photo::apply(source, e).pixelColor(0, 0).red() - 128) < 100);
        e = {};
        e.maxSide = 100;
        QCOMPARE(Photo::apply(source, e).size(), QSize(100, 50));
        e.mirror = true;
        QCOMPARE(Photo::apply(source, e).pixelColor(99, 0).red(), Photo::apply(source, e).pixelColor(99, 0).red());
        const QStringList taken = {QStringLiteral("Plage (modifiée).jpg")};
        QCOMPARE(Photo::copyName(QStringLiteral("Plage"), QStringLiteral("jpg"), QStringLiteral("modifiée"), [&](const QString &n) { return taken.contains(n); }),
                 QStringLiteral("Plage (modifiée 2).jpg"));
    }

    void folder()
    {
        QTemporaryDir dir;
        QImage image(64, 48, QImage::Format_RGB32);
        image.fill(Qt::blue);
        for (const char *name : {"10 b.png", "2 a.png", "1 c.jpg", "notes.txt"})
            QVERIFY(QString::fromLatin1(name).endsWith(QLatin1String(".txt")) ? QFile(dir.filePath(QString::fromLatin1(name))).open(QIODevice::WriteOnly)
                                                                             : image.save(dir.filePath(QString::fromLatin1(name))));
        Viewer viewer;
        QVERIFY(viewer.open(dir.filePath(QStringLiteral("2 a.png"))));
        QStringList names;
        for (const QString &f : viewer.files())
            names << QFileInfo(f).fileName();
        QCOMPARE(names, (QStringList{QStringLiteral("1 c.jpg"), QStringLiteral("2 a.png"), QStringLiteral("10 b.png")}));   // ordre naturel
        QCOMPARE(viewer.index(), 1);
        QCOMPARE(viewer.info().value(QStringLiteral("width")).toInt(), 64);
        viewer.next();
        viewer.next();
        QCOMPARE(viewer.index(), 0);   // on boucle

        // Modifier puis enregistrer une copie : l'original est intact.
        QVERIFY(viewer.beginEdit());
        viewer.rotate(1);
        QVERIFY(viewer.modified());
        QCOMPARE(viewer.editedSize(), QSize(48, 64));
        const QString copy = viewer.saveCopy();
        QCOMPARE(QFileInfo(copy).fileName(), QStringLiteral("1 c (modifiée).jpg"));
        QCOMPARE(QImage(copy).size(), QSize(48, 64));
        QCOMPARE(QImage(dir.filePath(QStringLiteral("1 c.jpg"))).size(), QSize(64, 48));
        viewer.undo();
        QVERIFY(!viewer.modified());
    }
};

QTEST_MAIN(TestViewer)
#include "tst_viewer.moc"
