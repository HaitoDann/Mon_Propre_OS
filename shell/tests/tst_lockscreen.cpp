// Banc de test de l'écran de verrouillage : un faux « authenticator » reproduit l'interface
// de kscreenlocker (startAuthenticating → promptForSecretChanged → respond → succeeded/failed).
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickItem>
#include <QQuickView>
#include <QSignalSpy>
#include <QTest>

class FakeAuthenticator : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString promptForSecret READ promptForSecret NOTIFY promptForSecretChanged)
    Q_PROPERTY(QString infoMessage READ empty NOTIFY infoMessageChanged)
    Q_PROPERTY(QString errorMessage READ empty NOTIFY errorMessageChanged)
public:
    bool busy() const { return m_busy; }
    QString promptForSecret() const { return QStringLiteral("Mot de passe :"); }
    QString empty() const { return {}; }
    Q_INVOKABLE void startAuthenticating() { ++starts; m_busy = true; Q_EMIT busyChanged(); Q_EMIT promptForSecretChanged(); }
    Q_INVOKABLE void respond(const QByteArray &secret)
    {
        lastSecret = secret;
        m_busy = false;
        Q_EMIT busyChanged();
        if (secret == "bon-mot-de-passe") Q_EMIT succeeded(); else Q_EMIT failed();
    }
    int starts = 0;
    QByteArray lastSecret;
Q_SIGNALS:
    void busyChanged(); void promptForSecretChanged(); void infoMessageChanged(); void errorMessageChanged();
    void succeeded(); void failed();
private:
    bool m_busy = false;
};

static void typeText(QWindow *w, const QString &text)
{
    for (const QChar c : text)
        QTest::keyClick(w, c.toLatin1());
}

class TestLockScreen : public QObject
{
    Q_OBJECT
    QQuickView *view = nullptr;
    FakeAuthenticator auth;
private Q_SLOTS:
    void init()
    {
        view = new QQuickView;
        view->setResizeMode(QQuickView::SizeRootObjectToView);   // comme kscreenlocker
        view->engine()->addImportPath(QStringLiteral(VINX_BUILD_QML_DIR));
        view->rootContext()->setContextProperty(QStringLiteral("authenticator"), &auth);
        view->rootContext()->setContextProperty(QStringLiteral("kscreenlocker_userName"), QStringLiteral("vinx"));
        view->setSource(QUrl::fromLocalFile(QStringLiteral(LOCKSCREEN_QML)));
        QCOMPARE(view->status(), QQuickView::Ready);   // aucune erreur de chargement → pas d'écran de secours KDE
        view->resize(1280, 800);
        view->rootObject()->setProperty("locked", true);
        view->show();
        QVERIFY(QTest::qWaitForWindowExposed(view));
    }
    void cleanup() { delete view; }

    void wrongPasswordShowsMessageAndStaysLocked()
    {
        QSignalSpy quit(view->engine(), &QQmlEngine::quit);
        typeText(view, QStringLiteral("faux"));
        QTest::keyClick(view, Qt::Key_Return);
        QCOMPARE(auth.lastSecret, QByteArray("faux"));
        QCOMPARE(quit.count(), 0);
        QCOMPARE(view->rootObject()->property("message").toString(), QStringLiteral("Mot de passe incorrect."));
    }
    void rightPasswordUnlocks()
    {
        QSignalSpy quit(view->engine(), &QQmlEngine::quit);
        typeText(view, QStringLiteral("bon-mot-de-passe"));
        QTest::keyClick(view, Qt::Key_Return);
        QCOMPARE(auth.lastSecret, QByteArray("bon-mot-de-passe"));
        QCOMPARE(quit.count(), 1);
    }
    void screenshot()
    {
        const QByteArray out = qgetenv("VINX_LOCKSCREEN_SHOT");
        if (!out.isEmpty())
            view->grabWindow().save(QString::fromLocal8Bit(out));
    }
};

QTEST_MAIN(TestLockScreen)
#include "tst_lockscreen.moc"
