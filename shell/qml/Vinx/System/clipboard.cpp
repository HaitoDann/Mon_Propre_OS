#include "clipboard.h"

#include <QBuffer>
#include <QCryptographicHash>
#include <QClipboard>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QImage>
#include <QJsonDocument>
#include <QMimeData>
#include <QStandardPaths>

#ifdef VINX_HAVE_GUIADDONS
#include <KSystemClipboard>
#endif

namespace {
QByteArray toPng(const QImage &image)
{
    QByteArray png;
    QBuffer buffer(&png);
    buffer.open(QIODevice::WriteOnly);
    image.save(&buffer, "PNG");
    return png;
}

QByteArray pixelKey(const QImage &image)
{
    const QImage argb = image.convertToFormat(QImage::Format_ARGB32);
    QCryptographicHash h(QCryptographicHash::Sha1);
    h.addData(QByteArrayView(reinterpret_cast<const char *>(argb.constBits()), argb.sizeInBytes()));
    return h.result();
}

QString thumbnail(const QByteArray &png)
{
    QImage image;
    image.loadFromData(png, "PNG");
    if (image.isNull())
        return {};
    return QStringLiteral("data:image/png;base64,") + QString::fromLatin1(toPng(image.scaled(96, 96, Qt::KeepAspectRatio, Qt::SmoothTransformation)).toBase64());
}
}

Clipboard::Clipboard(QObject *parent)
    : QObject(parent)
{
    loadPinned();
#ifdef VINX_HAVE_GUIADDONS
    connect(KSystemClipboard::instance(), &KSystemClipboard::changed, this, [this](QClipboard::Mode mode) {
        if (mode == QClipboard::Clipboard)
            onChanged();
    });
#else
    connect(QGuiApplication::clipboard(), &QClipboard::dataChanged, this, &Clipboard::onChanged);
#endif
}

const QMimeData *Clipboard::current() const
{
#ifdef VINX_HAVE_GUIADDONS
    return KSystemClipboard::instance()->mimeData(QClipboard::Clipboard);
#else
    return QGuiApplication::clipboard()->mimeData(QClipboard::Clipboard);
#endif
}

void Clipboard::onChanged()
{
    if (m_publishing)
        return;
    const QMimeData *data = current();
    // L'application qui avait copié s'est fermée : on remet le dernier élément (comme Klipper),
    // sauf s'il s'agissait d'un mot de passe.
    if (!data || data->formats().isEmpty()) {
        if (!m_secret && !m_history.items().isEmpty())
            publish(m_history.items().constFirst());
        return;
    }
    capture(data);
}

void Clipboard::capture(const QMimeData *data)
{
    // Gestionnaires de mots de passe (KeePassXC…) : jamais dans l'historique.
    m_secret = data->data(QStringLiteral("x-kde-passwordManagerHint")) == "secret";
    if (m_secret)
        return;
    ClipItem item;
    item.time = QDateTime::currentMSecsSinceEpoch();
    if (data->hasImage()) {
        const QImage image = qvariant_cast<QImage>(data->imageData());
        if (image.isNull() || qint64(image.width()) * image.height() > 40'000'000)
            return;
        item.kind = ClipItem::Image;
        item.key = pixelKey(image);
        item.png = toPng(image);
        item.text = QStringLiteral("%1 × %2").arg(image.width()).arg(image.height());
    } else if (data->hasText()) {
        item.text = data->text();
        item.kind = ClipHistory::kindOfText(item.text);
    } else {
        return;
    }
    if (m_history.add(item))
        Q_EMIT itemsChanged();
}

void Clipboard::publish(const ClipItem &item)
{
    auto *data = new QMimeData;
    if (item.kind == ClipItem::Image) {
        QImage image;
        image.loadFromData(item.png, "PNG");
        data->setImageData(image);
    } else {
        data->setText(item.text);
    }
    m_publishing = true;
#ifdef VINX_HAVE_GUIADDONS
    KSystemClipboard::instance()->setMimeData(data, QClipboard::Clipboard);
#else
    QGuiApplication::clipboard()->setMimeData(data, QClipboard::Clipboard);
#endif
    m_publishing = false;
}

QVariantList Clipboard::items() const
{
    QVariantList out;
    for (const ClipItem &c : m_history.items()) {
        static const char *kinds[] = {"text", "link", "image"};
        out.append(QVariantMap{{QStringLiteral("id"), c.id}, {QStringLiteral("kind"), QString::fromLatin1(kinds[c.kind])},
                               {QStringLiteral("text"), c.text.left(400)}, {QStringLiteral("time"), double(c.time)},
                               {QStringLiteral("pinned"), c.pinned},
                               {QStringLiteral("thumbnail"), c.kind == ClipItem::Image ? thumbnail(c.png) : QString()}});
    }
    return out;
}

void Clipboard::activate(const QString &id)
{
    const int i = m_history.indexOf(id);
    if (i < 0)
        return;
    ClipItem item = m_history.items().at(i);
    item.time = QDateTime::currentMSecsSinceEpoch();
    m_history.add(item);
    m_secret = false;
    publish(item);
    Q_EMIT itemsChanged();
}

void Clipboard::setPinned(const QString &id, bool pinned)
{
    if (m_history.setPinned(id, pinned)) {
        savePinned();
        Q_EMIT itemsChanged();
    }
}

void Clipboard::remove(const QString &id)
{
    const int i = m_history.indexOf(id);
    const bool pinned = i >= 0 && m_history.items().at(i).pinned;
    if (m_history.remove(id)) {
        if (pinned)
            savePinned();
        Q_EMIT itemsChanged();
    }
}

void Clipboard::clear()
{
    m_history.clearUnpinned();
    Q_EMIT itemsChanged();
}

void Clipboard::copyImageFile(const QString &path)
{
    const QImage image(path);
    if (image.isNull())
        return;
    ClipItem item;
    item.kind = ClipItem::Image;
    item.key = pixelKey(image);
    item.png = toPng(image);
    item.text = QStringLiteral("%1 × %2").arg(image.width()).arg(image.height());
    item.time = QDateTime::currentMSecsSinceEpoch();
    m_history.add(item);
    m_secret = false;
    publish(m_history.items().constFirst());
    Q_EMIT itemsChanged();
}

void Clipboard::copyText(const QString &text)
{
    ClipItem item;
    item.text = text;
    item.kind = ClipHistory::kindOfText(text);
    item.time = QDateTime::currentMSecsSinceEpoch();
    if (!m_history.add(item) && (m_history.items().isEmpty() || m_history.items().constFirst().text != text))
        return;
    m_secret = false;
    publish(m_history.items().constFirst());
    Q_EMIT itemsChanged();
}

// ---------- Épinglés ----------

QString Clipboard::storeDir() const
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/vinx/clipboard");
}

void Clipboard::savePinned() const
{
    const QString dir = storeDir();
    QDir().mkpath(dir);
    QStringList keep;
    for (const ClipItem &c : m_history.items()) {
        if (!c.pinned || c.kind != ClipItem::Image)
            continue;
        keep << c.id + QStringLiteral(".png");
        QFile f(dir + QLatin1Char('/') + c.id + QStringLiteral(".png"));
        if (!f.exists() && f.open(QIODevice::WriteOnly))
            f.write(c.png);
    }
    // Images désépinglées : effacées du disque.
    const auto files = QDir(dir).entryList({QStringLiteral("*.png")}, QDir::Files);
    for (const QString &file : files)
        if (!keep.contains(file))
            QFile::remove(dir + QLatin1Char('/') + file);
    QFile f(dir + QStringLiteral("/pinned.json"));
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        f.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner);
        f.write(QJsonDocument(m_history.pinnedToJson()).toJson(QJsonDocument::Compact));
    }
}

void Clipboard::loadPinned()
{
    const QString dir = storeDir();
    QFile f(dir + QStringLiteral("/pinned.json"));
    if (!f.open(QIODevice::ReadOnly))
        return;
    m_history.loadPinned(QJsonDocument::fromJson(f.readAll()).array(), [dir](const QString &id) {
        QFile image(dir + QLatin1Char('/') + id + QStringLiteral(".png"));
        return image.open(QIODevice::ReadOnly) ? image.readAll() : QByteArray();
    }, [](const QByteArray &png) {
        QImage image;
        image.loadFromData(png, "PNG");
        return pixelKey(image);
    });
}
