#pragma once

#include <QHash>
#include <QImage>
#include <QObject>
#include <QQuickImageProvider>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>
#include <functional>

class QQmlEngine;
class QJSEngine;

#include "captureutil.h"

// Capture d'écran VinX (ADR 0036) : images des écrans et de la fenêtre choisie par KWin
// (org.kde.KWin.ScreenShot2), puis document annoté, copié et enregistré.
// Une seule instance, enregistrée dans le moteur QML par main.cpp (singleton « Shot »).
// Hors KWin (tests, captures de la documentation) : VINX_SCREENSHOT_IMAGE remplace l'écran.
class Shot : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList screens READ screens NOTIFY screensReady)
    Q_PROPERTY(bool hasImage READ hasImage NOTIFY changed)
    Q_PROPERTY(int imageWidth READ imageWidth NOTIFY changed)
    Q_PROPERTY(int imageHeight READ imageHeight NOTIFY changed)
    Q_PROPERTY(int revision READ revision NOTIFY changed)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY changed)
    Q_PROPERTY(QString savedPath READ savedPath NOTIFY changed)
    Q_PROPERTY(QString mode READ mode CONSTANT)

public:
    explicit Shot(QObject *parent = nullptr);
    static Shot *instance();

    QVariantList screens() const { return m_screenList; }
    bool hasImage() const { return !m_image.isNull(); }
    int imageWidth() const { return m_image.width(); }
    int imageHeight() const { return m_image.height(); }
    int revision() const { return m_revision; }
    bool canUndo() const { return !m_shapes.isEmpty(); }
    QString savedPath() const { return m_savedPath; }
    QString mode() const { return m_mode; }
    void setMode(const QString &mode) { m_mode = mode; }

    QImage screenImage(const QString &name) const { return m_screens.value(name); }
    QImage rendered() const { return m_rendered; }

    Q_INVOKABLE void grabScreens();
    Q_INVOKABLE void takeArea(const QString &screen, qreal x, qreal y, qreal width, qreal height);
    Q_INVOKABLE void takeScreen(const QString &screen);
    Q_INVOKABLE void takeWindow();      // KWin : clic sur la fenêtre voulue
    Q_INVOKABLE void takeWorkspace();   // tous les écrans (Impr. écran)
    Q_INVOKABLE bool load(const QString &file);
    Q_INVOKABLE QString cursorScreen() const;

    Q_INVOKABLE void addShape(const QVariantMap &shape);
    Q_INVOKABLE void undo();
    Q_INVOKABLE void copy();
    Q_INVOKABLE QString save();
    Q_INVOKABLE void openFolder() const;
    Q_INVOKABLE void notifySaved();     // bulle « Capture enregistrée » avec « Annoter »

Q_SIGNALS:
    void screensReady();
    void changed();
    void captured();
    void failed(const QString &message);
    void annotateRequested();

private Q_SLOTS:
    void onNotificationAction(uint id, const QString &action);

private:
    using Callback = std::function<void(const QImage &)>;
    void kwinCall(const QString &method, const QVariantList &args, const Callback &done);
    bool kwinAvailable() const;
    void setCapture(const QImage &image);
    void rerender();

    QString m_mode;
    QHash<QString, QImage> m_screens;
    QVariantList m_screenList;
    QImage m_image, m_rendered;
    QList<Capture::Shape> m_shapes;
    int m_revision = 0;
    QString m_savedPath;
    uint m_notification = 0;
};

// image://shot/screen/<nom> : écran figé ; image://shot/capture/<révision> : capture annotée.
class ShotImageProvider : public QQuickImageProvider
{
public:
    ShotImageProvider() : QQuickImageProvider(QQuickImageProvider::Image) {}
    QImage requestImage(const QString &id, QSize *size, const QSize &requested) override;
};
