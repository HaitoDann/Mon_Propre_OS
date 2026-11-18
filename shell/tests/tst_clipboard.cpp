#include <QBuffer>
#include <QImage>
#include <QMimeData>
#include <QTemporaryDir>
#include <QtTest>

#include "clipboard.h"
#include "cliphistory.h"

// Historique du presse-papiers (ADR 0037).
class TestClipboard : public QObject
{
    Q_OBJECT

    static ClipItem text(const QString &t)
    {
        ClipItem c;
        c.text = t;
        c.kind = ClipHistory::kindOfText(t);
        return c;
    }

private Q_SLOTS:
    void initTestCase()
    {
        static QTemporaryDir dir;
        qputenv("XDG_DATA_HOME", dir.path().toUtf8());
    }

    void historyOrderAndLimit()
    {
        ClipHistory h;
        QVERIFY(h.add(text(QStringLiteral("un"))));
        QVERIFY(h.add(text(QStringLiteral("deux"))));
        QVERIFY(!h.add(text(QStringLiteral("deux"))));       // déjà en tête : rien ne change
        QVERIFY(h.add(text(QStringLiteral("un"))));           // doublon : remonté, pas copié
        QCOMPARE(h.items().size(), 2);
        QCOMPARE(h.items().at(0).text, QStringLiteral("un"));
        QVERIFY(!h.add(text(QStringLiteral("   "))));         // vide : ignoré
        QVERIFY(h.setPinned(h.items().at(1).id, true));      // « deux » épinglé
        for (int i = 0; i < 60; ++i)
            h.add(text(QStringLiteral("élément %1").arg(i)));
        QCOMPARE(h.items().size(), ClipHistory::kLimit + 1); // 50 + l'épinglé, gardé même tout en bas
        QVERIFY(h.indexOf(h.items().last().id) >= 0);
        QCOMPARE(h.items().last().text, QStringLiteral("deux"));
        h.clearUnpinned();
        QCOMPARE(h.items().size(), 1);
        QCOMPARE(ClipHistory::kindOfText(QStringLiteral("https://debian.org/x")), ClipItem::Link);
        QCOMPARE(ClipHistory::kindOfText(QStringLiteral("voir https://debian.org")), ClipItem::Text);
    }

    void pinnedRoundTrip()
    {
        ClipHistory h;
        h.add(text(QStringLiteral("secret pas épinglé")));
        ClipItem img;
        img.kind = ClipItem::Image;
        img.png = QByteArray("PNG-OCTETS");
        img.text = QStringLiteral("2 × 2");
        h.add(img);
        h.setPinned(h.items().at(0).id, true);
        const QJsonArray json = h.pinnedToJson();
        QCOMPARE(json.size(), 1);   // seuls les épinglés vont sur le disque
        ClipHistory restored;
        restored.loadPinned(json, [](const QString &) { return QByteArray("PNG-OCTETS"); });
        QCOMPARE(restored.items().size(), 1);
        QCOMPARE(restored.items().at(0).kind, ClipItem::Image);
        QVERIFY(restored.items().at(0).pinned);
        // Un nouvel élément ne réutilise pas l'identifiant d'un épinglé rechargé.
        restored.add(text(QStringLiteral("nouveau")));
        QVERIFY(restored.items().at(0).id != restored.items().at(1).id);
    }

    void captureMime()
    {
        Clipboard board;
        const int before = board.items().size();
        QMimeData plain;
        plain.setText(QStringLiteral("Réunion jeudi"));
        board.capture(&plain);
        QCOMPARE(board.items().size(), before + 1);
        QCOMPARE(board.items().at(0).toMap().value(QStringLiteral("text")).toString(), QStringLiteral("Réunion jeudi"));

        // Mot de passe copié depuis KeePassXC : jamais gardé.
        QMimeData password;
        password.setText(QStringLiteral("hunter2"));
        password.setData(QStringLiteral("x-kde-passwordManagerHint"), "secret");
        board.capture(&password);
        QCOMPARE(board.items().size(), before + 1);

        QImage image(4, 2, QImage::Format_ARGB32);
        image.fill(Qt::red);
        QMimeData picture;
        picture.setImageData(image);
        board.capture(&picture);
        const QVariantMap top = board.items().at(0).toMap();
        QCOMPARE(top.value(QStringLiteral("kind")).toString(), QStringLiteral("image"));
        QCOMPARE(top.value(QStringLiteral("text")).toString(), QStringLiteral("4 × 2"));
        QVERIFY(top.value(QStringLiteral("thumbnail")).toString().startsWith(QStringLiteral("data:image/png;base64,")));
        // La même image relue du presse-papiers (autre encodage) n'est pas dupliquée.
        board.capture(&picture);
        QCOMPARE(board.items().size(), before + 2);
    }
};

QTEST_MAIN(TestClipboard)
#include "tst_clipboard.moc"
