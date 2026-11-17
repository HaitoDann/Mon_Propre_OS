#include <QtTest>
#include <crypt.h>
#include "accounts.h"

class TestAccounts : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void hash()
    {
        const QString h = Accounts::hashPassword(QStringLiteral("Mot de passe é 123"));
        QVERIFY(h.startsWith("$y$") || h.startsWith("$6$"));
        // Le même mot de passe, haché avec ce sel, redonne le même résultat (vérification de connexion).
        struct crypt_data d = {};
        QCOMPARE(QString::fromLatin1(crypt_r("Mot de passe é 123", h.toLatin1().constData(), &d)), h);
        QVERIFY(Accounts::hashPassword(QStringLiteral("x")) != Accounts::hashPassword(QStringLiteral("x")));   // sel aléatoire
    }
    void names()
    {
        QCOMPARE(Accounts::suggestUserName(QStringLiteral("Élodie Martin")), QStringLiteral("elodie"));
        QCOMPARE(Accounts::suggestUserName(QStringLiteral("2pac")), QStringLiteral("u2pac"));
        QVERIFY(Accounts::validUserName(QStringLiteral("marie")));
        QVERIFY(!Accounts::validUserName(QStringLiteral("Marie")));
        QVERIFY(!Accounts::validUserName(QStringLiteral("root")));
        QVERIFY(!Accounts::validUserName(QStringLiteral("a b")));
    }
};

QTEST_GUILESS_MAIN(TestAccounts)
#include "tst_accounts.moc"
