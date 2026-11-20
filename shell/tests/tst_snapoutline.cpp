// Aperçu des fenêtres aimantées (ADR 0042) : le QML généré pour KWin se charge avec un faux objet
// « outline » (même interface que KWin), suit l'accent et place la zone sur la géométrie visée.
#include "auroraetheme.h"
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickItem>
#include <QQuickWindow>
#include <QtTest>

class FakeOutline : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool active MEMBER active NOTIFY activeChanged)
    Q_PROPERTY(QRect geometry MEMBER geometry NOTIFY geometryChanged)
    Q_PROPERTY(QRect visualParentGeometry MEMBER visualParent NOTIFY visualParentGeometryChanged)
    Q_PROPERTY(QRect unifiedGeometry MEMBER unified NOTIFY unifiedGeometryChanged)
public:
    bool active = false;
    QRect geometry{0, 0, 960, 1080}, visualParent{300, 200, 800, 600}, unified{0, 0, 1100, 1080};
Q_SIGNALS:
    void activeChanged(); void geometryChanged(); void visualParentGeometryChanged(); void unifiedGeometryChanged();
};

class TestSnapOutline : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void followsAccent()
    {
        windowtheme::Colors c;
        c.accent = QColor(QStringLiteral("#2E9BFF"));
        const QString qml = QString::fromUtf8(windowtheme::outlineQml(c));
        QVERIFY(qml.contains(QStringLiteral("#2E9BFF")));
        QVERIFY(qml.contains(QStringLiteral("outline.active")));
        QVERIFY(!qml.contains(QStringLiteral("org.kde")));   // rien d'autre que QtQuick dans KWin
        QCOMPARE(windowtheme::outlinePaths().size(), 2);
    }
    void loadsAndSlidesToTarget()
    {
        QQmlEngine engine;
        FakeOutline outline;
        engine.rootContext()->setContextProperty(QStringLiteral("outline"), &outline);
        QQmlComponent component(&engine);
        component.setData(windowtheme::outlineQml({}), QUrl(QStringLiteral("file:///outline.qml")));
        QScopedPointer<QObject> obj(component.create());
        QVERIFY2(obj, qPrintable(component.errorString()));
        auto *window = qobject_cast<QQuickWindow *>(obj.data());
        QVERIFY(window);
        QVERIFY(!window->isVisible());
        outline.active = true;
        Q_EMIT outline.activeChanged();
        QVERIFY(window->isVisible());
        QCOMPARE(window->width(), 1100);
        auto *zone = window->contentItem()->childItems().value(0);
        QVERIFY(zone);
        QTRY_COMPARE(zone->width(), 960.0);
        QTRY_COMPARE(zone->height(), 1080.0);
        QCOMPARE(zone->x(), 0.0);
        // Changement de cible pendant le glissement (coin) : la zone suit.
        outline.geometry = QRect(550, 0, 550, 540);
        Q_EMIT outline.geometryChanged();
        QTRY_COMPARE(zone->x(), 550.0);
        QTRY_COMPARE(zone->height(), 540.0);
    }
};

QTEST_MAIN(TestSnapOutline)
#include "tst_snapoutline.moc"
