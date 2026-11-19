#include "shot.h"

#include <QClipboard>
#include <QCursor>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusUnixFileDescriptor>
#include <QDesktopServices>
#include <QDir>
#include <QGuiApplication>
#include <QQmlEngine>
#include <QScreen>
#include <QStandardPaths>
#include <QThread>
#include <QUrl>

#include <fcntl.h>
#include <unistd.h>

namespace {
const QString kService = QStringLiteral("org.kde.KWin.ScreenShot2");
const QString kPath = QStringLiteral("/org/kde/KWin/ScreenShot2");
Shot *s_instance = nullptr;

// Image de remplacement hors KWin, mise à la taille de l'écran.
QImage fallbackImage(const QSize &size)
{
    const QString file = qEnvironmentVariable("VINX_SCREENSHOT_IMAGE");
    if (file.isEmpty())
        return {};
    const QImage image(file);
    return size.isValid() && !image.isNull() ? image.scaled(size, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation).copy(QRect(QPoint(), size)) : image;
}
}

Shot::Shot(QObject *parent)
    : QObject(parent)
{
    s_instance = this;
    QDBusConnection::sessionBus().connect(QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("/org/freedesktop/Notifications"),
                                          QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("ActionInvoked"), this,
                                          SLOT(onNotificationAction(uint,QString)));
}

Shot *Shot::instance()
{
    if (!s_instance)
        new Shot(qApp);
    return s_instance;
}

bool Shot::kwinAvailable() const
{
    if (qEnvironmentVariableIsSet("VINX_SCREENSHOT_IMAGE"))
        return false;
    auto *bus = QDBusConnection::sessionBus().interface();
    return bus && bus->isServiceRegistered(kService);
}

// Appel KWin : l'image arrive par un tube, lu dans un fil à part pendant que KWin l'écrit.
void Shot::kwinCall(const QString &method, const QVariantList &args, const Callback &done)
{
    int fds[2];
    if (pipe2(fds, O_CLOEXEC) != 0) {
        done({});
        return;
    }
    QDBusMessage msg = QDBusMessage::createMethodCall(kService, kPath, kService, method);
    msg.setArguments(QVariantList(args) << QVariant::fromValue(QDBusUnixFileDescriptor(fds[1])));
    ::close(fds[1]);   // KWin a sa propre copie : la lecture s'arrête quand il a fini d'écrire

    struct State {
        QByteArray data;
        QVariantMap meta;
        bool read = false, replied = false, ok = false;
    };
    auto state = std::make_shared<State>();
    auto finish = [this, state, done] {
        if (!state->read || !state->replied)
            return;
        const QImage image = state->ok ? Capture::imageFromRaw(state->data, state->meta) : QImage();
        done(image);
    };
    QThread *reader = QThread::create([fd = fds[0], state] {
        char buf[65536];
        ssize_t n;
        while ((n = ::read(fd, buf, sizeof buf)) > 0 || (n < 0 && errno == EINTR)) {
            if (n > 0)
                state->data.append(buf, n);
        }
        ::close(fd);
    });
    connect(reader, &QThread::finished, this, [state, finish, reader] {
        state->read = true;
        reader->deleteLater();
        finish();
    });
    reader->start();
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(msg, 10 * 60 * 1000), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, state, finish, watcher, method] {
        QDBusPendingReply<QVariantMap> reply = *watcher;
        watcher->deleteLater();
        state->replied = true;
        state->ok = !reply.isError();
        if (state->ok)
            state->meta = reply.value();
        else if (reply.error().name() != QLatin1String("org.kde.KWin.ScreenShot2.Error.Cancelled"))
            qWarning("KWin %s : %s", qPrintable(method), qPrintable(reply.error().message()));
        finish();
    });
}

void Shot::grabScreens()
{
    const auto screens = QGuiApplication::screens();
    m_screens.clear();
    m_screenList.clear();
    for (QScreen *screen : screens) {
        const QRect g = screen->geometry();
        m_screenList.append(QVariantMap{{QStringLiteral("name"), screen->name()}, {QStringLiteral("x"), g.x()}, {QStringLiteral("y"), g.y()},
                                        {QStringLiteral("width"), g.width()}, {QStringLiteral("height"), g.height()}});
    }
    if (!kwinAvailable()) {
        for (QScreen *screen : screens) {
            QImage image = fallbackImage(screen->geometry().size() * screen->devicePixelRatio());
            if (image.isNull())
                image = screen->grabWindow(0).toImage();
            image.setDevicePixelRatio(screen->devicePixelRatio());
            m_screens.insert(screen->name(), image);
        }
        Q_EMIT screensReady();
        return;
    }
    auto pending = std::make_shared<int>(screens.size());
    const QVariantMap options{{QStringLiteral("native-resolution"), true}, {QStringLiteral("include-cursor"), false}};
    for (QScreen *screen : screens) {
        const QString name = screen->name();
        kwinCall(QStringLiteral("CaptureScreen"), {name, options}, [this, name, pending](const QImage &image) {
            m_screens.insert(name, image);
            if (--*pending == 0)
                Q_EMIT screensReady();
        });
    }
}

QString Shot::cursorScreen() const
{
    QScreen *s = QGuiApplication::screenAt(QCursor::pos());
    return (s ? s : QGuiApplication::primaryScreen())->name();
}

void Shot::takeArea(const QString &screen, qreal x, qreal y, qreal width, qreal height)
{
    const QImage image = m_screens.value(screen);
    QSize logical;
    for (const QVariant &v : std::as_const(m_screenList)) {
        const QVariantMap m = v.toMap();
        if (m.value(QStringLiteral("name")).toString() == screen)
            logical = QSize(m.value(QStringLiteral("width")).toInt(), m.value(QStringLiteral("height")).toInt());
    }
    if (image.isNull() || logical.isEmpty() || width < 1 || height < 1) {
        Q_EMIT failed(tr("La capture a échoué."));
        return;
    }
    const qreal scale = qreal(image.width()) / logical.width();
    QImage crop = image.copy(QRectF(x * scale, y * scale, width * scale, height * scale).toAlignedRect());
    crop.setDevicePixelRatio(scale);
    setCapture(crop);
}

void Shot::takeScreen(const QString &screen)
{
    QImage image = m_screens.value(screen);
    if (image.isNull()) {
        Q_EMIT failed(tr("La capture a échoué."));
        return;
    }
    setCapture(image);
}

void Shot::takeWindow()
{
    if (!kwinAvailable()) {
        Q_EMIT failed(tr("La capture d'une fenêtre demande KWin."));
        return;
    }
    const QVariantMap options{{QStringLiteral("include-decoration"), true}, {QStringLiteral("include-shadow"), false},
                              {QStringLiteral("native-resolution"), true}};
    kwinCall(QStringLiteral("CaptureInteractive"), {uint(0), options}, [this](const QImage &image) {
        if (image.isNull())
            Q_EMIT failed(QString());   // annulée (Échap)
        else
            setCapture(image);
    });
}

void Shot::takeWorkspace()
{
    if (!kwinAvailable()) {
        QScreen *primary = QGuiApplication::primaryScreen();
        QImage image = fallbackImage(primary ? primary->geometry().size() : QSize());
        if (image.isNull() && primary)
            image = primary->grabWindow(0).toImage();
        image.isNull() ? Q_EMIT failed(tr("La capture a échoué.")) : setCapture(image);
        return;
    }
    kwinCall(QStringLiteral("CaptureWorkspace"), {QVariantMap{{QStringLiteral("native-resolution"), true}}}, [this](const QImage &image) {
        image.isNull() ? Q_EMIT failed(tr("La capture a échoué.")) : setCapture(image);
    });
}

bool Shot::load(const QString &file)
{
    const QImage image(file);
    if (image.isNull())
        return false;
    m_savedPath = file;
    m_image = image;
    m_shapes.clear();
    rerender();
    Q_EMIT captured();
    return true;
}

// Toute nouvelle capture est aussitôt copiée (choix validé : on la colle tout de suite).
void Shot::setCapture(const QImage &image)
{
    m_image = image;
    m_shapes.clear();
    m_savedPath.clear();
    rerender();
    copy();
    Q_EMIT captured();
}

void Shot::rerender()
{
    m_rendered = Capture::render(m_image, m_shapes);
    ++m_revision;
    Q_EMIT changed();
}

void Shot::addShape(const QVariantMap &shape)
{
    m_shapes.append(Capture::shapeFromMap(shape));
    rerender();
}

void Shot::undo()
{
    if (m_shapes.isEmpty())
        return;
    m_shapes.removeLast();
    rerender();
}

// Copie : confiée au shell VinX s'il tourne (il garde l'image après la fermeture de cette
// fenêtre, ADR 0037), sinon au presse-papiers de Qt.
void Shot::copy()
{
    if (m_rendered.isNull())
        return;
    const QString runtime = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    const QString file = runtime + QStringLiteral("/vinx-capture.png");
    auto *bus = QDBusConnection::sessionBus().interface();
    if (!runtime.isEmpty() && bus && bus->isServiceRegistered(QStringLiteral("org.vinx.Shell")) && m_rendered.save(file, "PNG")) {
        QDBusMessage msg = QDBusMessage::createMethodCall(QStringLiteral("org.vinx.Shell"), QStringLiteral("/Shell"),
                                                          QStringLiteral("org.vinx.Shell"), QStringLiteral("copyImageFile"));
        msg.setArguments({file});
        if (QDBusConnection::sessionBus().call(msg, QDBus::Block, 3000).type() == QDBusMessage::ReplyMessage)
            return;
    }
    QGuiApplication::clipboard()->setImage(m_rendered);
}

QString Shot::save()
{
    if (m_rendered.isNull())
        return {};
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + QLatin1Char('/') + tr("Captures");
    QDir().mkpath(dir);
    QString path = m_savedPath;
    if (path.isEmpty() || !path.startsWith(dir))
        path = dir + QLatin1Char('/') + Capture::fileName(QDateTime::currentDateTime(), tr("Capture du %1 à %2"));
    if (!m_rendered.save(path, "PNG"))
        return {};
    m_savedPath = path;
    Q_EMIT changed();
    return path;
}

void Shot::openFolder() const
{
    const QString dir = m_savedPath.isEmpty() ? QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + QLatin1Char('/') + tr("Captures")
                                              : QFileInfo(m_savedPath).absolutePath();
    QDesktopServices::openUrl(QUrl::fromLocalFile(dir));
}

void Shot::notifySaved()
{
    QDBusMessage msg = QDBusMessage::createMethodCall(QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("/org/freedesktop/Notifications"),
                                                      QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("Notify"));
    msg.setArguments({tr("Capture d'écran"), uint(0), QStringLiteral("org.vinx.screenshot"), tr("Capture enregistrée"),
                      tr("Copiée dans le presse-papiers et enregistrée dans Images › Captures."),
                      QStringList{QStringLiteral("annotate"), tr("Annoter"), QStringLiteral("folder"), tr("Ouvrir le dossier")},
                      QVariantMap{{QStringLiteral("image-path"), m_savedPath}}, 8000});
    const QDBusMessage reply = QDBusConnection::sessionBus().call(msg, QDBus::Block, 3000);
    if (reply.type() == QDBusMessage::ReplyMessage && !reply.arguments().isEmpty())
        m_notification = reply.arguments().constFirst().toUInt();
}

void Shot::onNotificationAction(uint id, const QString &action)
{
    if (id != m_notification || m_notification == 0)
        return;
    if (action == QLatin1String("annotate"))
        Q_EMIT annotateRequested();
    else if (action == QLatin1String("folder"))
        openFolder();
}

QImage ShotImageProvider::requestImage(const QString &id, QSize *size, const QSize &requested)
{
    Shot *shot = Shot::instance();
    QImage image = id.startsWith(QLatin1String("screen/")) ? shot->screenImage(id.mid(7)) : shot->rendered();
    if (image.isNull()) {
        image = QImage(1, 1, QImage::Format_ARGB32);
        image.fill(Qt::transparent);
    } else if (requested.isValid()) {
        image = image.scaled(requested, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    if (size)
        *size = image.size();
    return image;
}
