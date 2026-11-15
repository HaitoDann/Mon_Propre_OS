#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtTest>

#include "fileops.h"
#include "foldermodel.h"

// Moteur local de Fichiers (le moteur KIO est vérifié par la CI Debian à la compilation).
class TestFiles : public QObject
{
    Q_OBJECT
    QTemporaryDir m_dir;

    QString path(const QString &rel) const { return m_dir.filePath(rel); }
    void touch(const QString &rel) { QFile f(path(rel)); QVERIFY(f.open(QIODevice::WriteOnly)); f.write("x"); }
    static QStringList names(const FolderModel &m)
    {
        QStringList out;
        for (int i = 0; i < m.count(); ++i)
            out << m.get(i).value("name").toString();
        return out;
    }

private Q_SLOTS:
    void initTestCase()
    {
        QVERIFY(m_dir.isValid());
        QDir(m_dir.path()).mkdir("dossier");
        touch("fichier10.txt");
        touch("fichier2.txt");
        touch(".cache");
    }

    void sortAndHidden()
    {
        FolderModel m;
        m.setUrl(QUrl::fromLocalFile(m_dir.path()));
        QCOMPARE(names(m), QStringList({"dossier", "fichier2.txt", "fichier10.txt"}));
        m.setShowHidden(true);
        QCOMPARE(m.count(), 4);
        m.setFilter("FICHIER1");
        QCOMPARE(names(m), QStringList({"fichier10.txt"}));
    }

    void uniqueNames()
    {
        const QStringList taken{"a.txt", "a (2).txt", "Dossier"};
        auto exists = [&taken](const QString &n) { return taken.contains(n); };
        QCOMPARE(uniqueName("b.txt", exists), QStringLiteral("b.txt"));
        QCOMPARE(uniqueName("a.txt", exists), QStringLiteral("a (3).txt"));
        QCOMPARE(uniqueName("Dossier", exists), QStringLiteral("Dossier (2)"));
    }

    void breadcrumbAndParent()
    {
        FolderModel m;
        m.setUrl(QUrl::fromLocalFile(path("dossier")));
        QCOMPARE(m.parentUrl(), QUrl::fromLocalFile(m_dir.path()));
        QCOMPARE(m.breadcrumb().last().toMap().value("name").toString(), QStringLiteral("dossier"));
        QCOMPARE(FolderModel::urlFromText("/tmp/"), QUrl::fromLocalFile("/tmp"));
    }

    void operations()
    {
        FileOps ops;
        QSignalSpy done(&ops, &FileOps::done);
        const QUrl dest = QUrl::fromLocalFile(path("dossier"));

        ops.copy({QUrl::fromLocalFile(path("fichier2.txt"))}, dest);
        QVERIFY(done.wait());
        QVERIFY(QFile::exists(path("dossier/fichier2.txt")));
        ops.copy({QUrl::fromLocalFile(path("fichier2.txt"))}, dest);   // conflit → « (2) »
        QVERIFY(done.wait());
        QVERIFY(QFile::exists(path("dossier/fichier2 (2).txt")));

        ops.move({QUrl::fromLocalFile(path("fichier10.txt"))}, dest);
        QVERIFY(done.wait());
        QVERIFY(!QFile::exists(path("fichier10.txt")));
        QVERIFY(QFile::exists(path("dossier/fichier10.txt")));

        ops.rename(QUrl::fromLocalFile(path("dossier/fichier10.txt")), "renommé.txt");
        QVERIFY(QFile::exists(path("dossier/renommé.txt")));

        const QString created = ops.createFolder(dest, "Nouveau dossier");
        QCOMPARE(created, QStringLiteral("Nouveau dossier"));
        QCOMPARE(ops.createFolder(dest, "Nouveau dossier"), QStringLiteral("Nouveau dossier (2)"));

        ops.copy({dest}, dest);   // dossier dans lui-même : refusé
        QSignalSpy failed(&ops, &FileOps::failed);
        QVERIFY(failed.wait() || failed.count() == 1);

        ops.deletePermanently({QUrl::fromLocalFile(path("dossier/renommé.txt"))});
        QVERIFY(!QFile::exists(path("dossier/renommé.txt")));
    }

    void sizes()
    {
        QVERIFY(FolderModel::formatSize(512).contains("512"));
        QCOMPARE(FolderModel::formatSize(1536), QLocale().toString(1.5, 'f', 1) + " Ko");
    }
};

QTEST_MAIN(TestFiles)
#include "tst_files.moc"
