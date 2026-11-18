#include "viewer.h"
#include "exif.h"

#include <QClipboard>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QImageReader>
#include <QImageWriter>
#include <QLocale>
#include <QMimeDatabase>
#include <QProcess>
#include <QSaveFile>
#include <QUrl>

#include <algorithm>

namespace {
constexpr int kPreviewSide = 2400;
Viewer *s_instance = nullptr;

QStringList imagePatterns()
{
    QStringList patterns;
    const auto formats = QImageReader::supportedImageFormats();
    for (const QByteArray &f : formats)
        patterns << QStringLiteral("*.") + QString::fromLatin1(f);
    patterns << QStringLiteral("*.jpeg") << QStringLiteral("*.jpg");
    patterns.removeDuplicates();
    return patterns;
}

QImage readImage(const QString &path)
{
    QImageReader reader(path);
    reader.setAutoTransform(true);   // orientation EXIF : la photo s'affiche droite
    return reader.read();
}
}

Viewer::Viewer(QObject *parent)
    : QObject(parent)
{
    s_instance = this;
}

Viewer *Viewer::instance()
{
    if (!s_instance)
        new Viewer(qApp);
    return s_instance;
}

bool Viewer::animated() const
{
    const QString s = QFileInfo(current()).suffix().toLower();
    if (s != QLatin1String("gif") && s != QLatin1String("webp"))
        return false;
    QImageReader reader(current());
    return reader.supportsAnimation() && reader.imageCount() > 1;
}

// Ouvre une image et liste les autres images du même dossier (ordre naturel : 2 avant 10).
bool Viewer::open(const QString &path)
{
    const QFileInfo fi(path);
    if (!fi.isFile())
        return false;
    QDir dir = fi.absoluteDir();
    QStringList names = dir.entryList(imagePatterns(), QDir::Files | QDir::Readable, QDir::NoSort);
    std::sort(names.begin(), names.end(), Photo::naturalLess);
    m_files.clear();
    for (const QString &n : std::as_const(names))
        m_files << dir.absoluteFilePath(n);
    if (!m_files.contains(fi.absoluteFilePath()))
        m_files.prepend(fi.absoluteFilePath());
    Q_EMIT folderChanged();
    m_index = -1;
    go(int(m_files.indexOf(fi.absoluteFilePath())));
    return true;
}

void Viewer::go(int index)
{
    if (index < 0 || index >= m_files.size() || index == m_index)
        return;
    m_index = index;
    m_source = QImage();
    m_history.clear();
    m_edits = {};
    loadInfo();
    Q_EMIT currentChanged();
    Q_EMIT editChanged();
}

void Viewer::loadInfo()
{
    const QString path = current();
    const QFileInfo fi(path);
    QImageReader reader(path);
    reader.setAutoTransform(true);
    QSize size = reader.size();
    QMimeDatabase mimes;
    m_info = {{QStringLiteral("name"), fi.fileName()},
              {QStringLiteral("folder"), fi.absolutePath()},
              {QStringLiteral("folderName"), fi.absoluteDir().dirName()},
              {QStringLiteral("bytes"), double(fi.size())},
              {QStringLiteral("format"), mimes.mimeTypeForFile(fi).comment()},
              {QStringLiteral("modified"), QLocale().toString(fi.lastModified(), QLocale::LongFormat)}};
    QFile f(path);
    if (f.open(QIODevice::ReadOnly)) {
        const Exif::Info exif = Exif::parse(Exif::jpegExifBlock(f.read(256 * 1024)));
        if (exif.valid) {
            if (exif.orientation >= 5 && size.isValid() && size.width() > size.height())
                size.transpose();   // certains lecteurs ne tournent pas la taille annoncée
            if (exif.taken.isValid())
                m_info.insert(QStringLiteral("taken"), QLocale().toString(exif.taken, tr("d MMMM yyyy 'à' HH:mm")));
            const QString camera = QStringList{exif.make, exif.model}.join(QLatin1Char(' ')).trimmed();
            if (!camera.isEmpty())
                m_info.insert(QStringLiteral("camera"), camera);
            QStringList settings;
            if (exif.fNumber > 0)
                settings << QStringLiteral("f/") + QLocale().toString(exif.fNumber, 'g', 2);
            if (exif.exposure > 0)
                settings << Exif::exposureText(exif.exposure);
            if (exif.iso > 0)
                settings << QStringLiteral("ISO %1").arg(exif.iso);
            if (exif.focal > 0)
                settings << QLocale().toString(exif.focal, 'g', 3) + QStringLiteral(" mm");
            if (!settings.isEmpty())
                m_info.insert(QStringLiteral("settings"), settings.join(QStringLiteral(" · ")));
        }
    }
    m_info.insert(QStringLiteral("width"), size.width());
    m_info.insert(QStringLiteral("height"), size.height());
}

bool Viewer::trash()
{
    const QString path = current();
    if (path.isEmpty() || !QFile::moveToTrash(path)) {
        Q_EMIT failed(tr("Impossible de mettre l'image à la corbeille."));
        return false;
    }
    const int i = m_index;
    m_files.removeAt(i);
    Q_EMIT folderChanged();
    m_index = -1;
    if (m_files.isEmpty()) {
        Q_EMIT currentChanged();
        return true;
    }
    go(qMin(i, int(m_files.size()) - 1));
    return true;
}

// Copie : confiée au shell VinX (l'image reste disponible après la fermeture du visionneur).
void Viewer::copyImage() const
{
    auto *bus = QDBusConnection::sessionBus().interface();
    if (bus && bus->isServiceRegistered(QStringLiteral("org.vinx.Shell"))) {
        QDBusMessage msg = QDBusMessage::createMethodCall(QStringLiteral("org.vinx.Shell"), QStringLiteral("/Shell"),
                                                          QStringLiteral("org.vinx.Shell"), QStringLiteral("copyImageFile"));
        msg.setArguments({current()});
        if (QDBusConnection::sessionBus().call(msg, QDBus::Block, 3000).type() == QDBusMessage::ReplyMessage)
            return;
    }
    QGuiApplication::clipboard()->setImage(readImage(current()));
}

bool Viewer::email() const
{
    return QProcess::startDetached(QStringLiteral("xdg-email"), {QStringLiteral("--attach"), current()});
}

void Viewer::openFolder() const
{
    QDesktopServices::openUrl(QUrl::fromLocalFile(QFileInfo(current()).absolutePath()));
}

void Viewer::openWith() const
{
    // Fichiers VinX propose « Ouvrir avec » ; sans lui, l'application par défaut.
    if (!QProcess::startDetached(QStringLiteral("vinx-files"), {current()}))
        QDesktopServices::openUrl(QUrl::fromLocalFile(current()));
}

bool Viewer::writeImage(const QImage &image, const QString &path) const
{
    QSaveFile file(path);   // jamais de fichier à moitié écrit en cas d'erreur
    if (!file.open(QIODevice::WriteOnly))
        return false;
    QImageWriter writer(&file, QFileInfo(path).suffix().toLower().toLatin1());
    if (!writer.canWrite())
        writer.setFormat("png");
    writer.setQuality(95);
    return writer.write(image) && file.commit();
}

bool Viewer::saveRotation(int quarterTurns)
{
    const QImage image = readImage(current());
    if (image.isNull() || !writeImage(Photo::rotated(image, quarterTurns, false), current()))
        return false;
    loadInfo();
    Q_EMIT currentChanged();
    return true;
}

// ---------- Mode Modifier ----------

bool Viewer::beginEdit()
{
    m_source = readImage(current());
    if (m_source.isNull())
        return false;
    m_small = qMax(m_source.width(), m_source.height()) > kPreviewSide
        ? m_source.scaled(kPreviewSide, kPreviewSide, Qt::KeepAspectRatio, Qt::SmoothTransformation)
        : m_source;
    m_edits = {};
    m_history.clear();
    editsChanged(false);
    return true;
}

void Viewer::editsChanged(bool remember)
{
    Q_UNUSED(remember);
    m_base = Photo::rotated(m_small, m_edits.quarterTurns, m_edits.mirror);
    Photo::Edits preview = m_edits;
    preview.maxSide = 0;   // l'aperçu garde sa taille, la réduction n'agit qu'à l'enregistrement
    m_preview = Photo::apply(m_small, preview);
    ++m_revision;
    Q_EMIT editChanged();
}

// Retouches à l'échelle de l'image d'origine (les annotations sont saisies sur l'aperçu).
Photo::Edits Viewer::fullEdits() const
{
    Photo::Edits e = m_edits;
    const double scale = m_small.width() > 0 ? double(m_source.width()) / m_small.width() : 1.0;
    for (Capture::Shape &s : e.shapes) {
        s.from *= scale;
        s.to *= scale;
    }
    return e;
}

QSize Viewer::editedSize() const
{
    if (m_source.isNull())
        return {};
    QSize s = m_edits.quarterTurns % 2 ? m_source.size().transposed() : m_source.size();
    s = Photo::cropRect(s, m_edits.crop).size();
    if (m_edits.maxSide > 0 && qMax(s.width(), s.height()) > m_edits.maxSide)
        s.scale(m_edits.maxSide, m_edits.maxSide, Qt::KeepAspectRatio);
    return s;
}

void Viewer::rotate(int quarterTurns)
{
    m_history << m_edits;
    m_edits.quarterTurns = ((m_edits.quarterTurns + quarterTurns) % 4 + 4) % 4;
    m_edits.crop = QRectF();   // le cadre n'a plus de sens après une rotation
    m_edits.shapes.clear();
    editsChanged();
}

void Viewer::flip()
{
    m_history << m_edits;
    m_edits.mirror = !m_edits.mirror;
    m_edits.shapes.clear();
    editsChanged();
}

void Viewer::setCrop(const QRectF &c)
{
    QRectF r = c.normalized().intersected(QRectF(0, 0, 1, 1));
    if (r.width() > 0.999 && r.height() > 0.999)
        r = QRectF();
    if (r == m_edits.crop)
        return;
    m_history << m_edits;
    m_edits.crop = r;
    m_edits.shapes.clear();
    editsChanged();
}

void Viewer::setBrightness(int v)
{
    v = qBound(-100, v, 100);
    if (v == m_edits.brightness)
        return;
    m_edits.brightness = v;
    editsChanged();
}

void Viewer::setContrast(int v)
{
    v = qBound(-100, v, 100);
    if (v == m_edits.contrast)
        return;
    m_edits.contrast = v;
    editsChanged();
}

void Viewer::setForMail(bool on)
{
    if (on == forMail())
        return;
    m_history << m_edits;
    m_edits.maxSide = on ? 1600 : 0;
    editsChanged();
}

void Viewer::addShape(const QVariantMap &shape)
{
    m_history << m_edits;
    m_edits.shapes << Capture::shapeFromMap(shape);
    editsChanged();
}

void Viewer::undo()
{
    if (m_history.isEmpty())
        return;
    m_edits = m_history.takeLast();
    editsChanged();
}

void Viewer::resetEdits()
{
    if (m_edits.isIdentity())
        return;
    m_history << m_edits;
    m_edits = {};
    editsChanged();
}

QString Viewer::saveCopy()
{
    const QFileInfo fi(current());
    QString suffix = fi.suffix().toLower();
    if (!QImageWriter::supportedImageFormats().contains(suffix.toLatin1()))
        suffix = QStringLiteral("png");   // HEIC, SVG… : copie en PNG
    const QString name = Photo::copyName(fi.completeBaseName(), suffix, tr("modifiée"), [&fi](const QString &n) {
        return fi.absoluteDir().exists(n);
    });
    const QString path = fi.absoluteDir().absoluteFilePath(name);
    if (name.isEmpty() || !writeImage(Photo::apply(m_source, fullEdits()), path)) {
        Q_EMIT failed(tr("L'enregistrement a échoué."));
        return {};
    }
    // La copie prend place juste après l'original dans la liste.
    m_files.insert(m_index + 1, path);
    Q_EMIT folderChanged();
    return path;
}

bool Viewer::replaceOriginal()
{
    if (!QImageWriter::supportedImageFormats().contains(QFileInfo(current()).suffix().toLower().toLatin1())
        || !writeImage(Photo::apply(m_source, fullEdits()), current())) {
        Q_EMIT failed(tr("L'enregistrement a échoué."));
        return false;
    }
    loadInfo();
    Q_EMIT currentChanged();
    return true;
}

QImage PhotoImageProvider::requestImage(const QString &id, QSize *size, const QSize &requested)
{
    QImage image = id.startsWith(QLatin1String("base/")) ? Viewer::instance()->baseImage() : Viewer::instance()->previewImage();
    if (image.isNull()) {
        image = QImage(1, 1, QImage::Format_ARGB32);
        image.fill(Qt::transparent);
    } else if (requested.isValid() && (requested.width() < image.width() || requested.height() < image.height())) {
        image = image.scaled(requested, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    if (size)
        *size = image.size();
    return image;
}
