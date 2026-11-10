#include <QTest>
#include "flatpak.h"

class TestFlatpak : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void progress()
    {
        QCOMPARE(Flatpak::parseProgress(QStringLiteral("Installing 1/3… 12%\rInstalling 1/3… 57%")), 57);
        QCOMPARE(Flatpak::parseProgress(QStringLiteral("Téléchargement : 100 %")), 100);
        QCOMPARE(Flatpak::parseProgress(QStringLiteral("Looking for matches…")), -1);
    }
};

QTEST_GUILESS_MAIN(TestFlatpak)
#include "tst_flatpak.moc"
