#pragma once

// Visionneur d'images VinX (ADR 0038) : lecture minimale des données EXIF d'une photo JPEG
// (date de prise de vue, appareil, ouverture, vitesse, ISO, focale, orientation).
// Testée dans tests/tst_viewer.cpp.

#include <QByteArray>
#include <QDateTime>
#include <QString>
#include <QtEndian>

namespace Exif {

struct Info {
    bool valid = false;
    QString make, model;
    QDateTime taken;
    double exposure = 0;   // secondes
    double fNumber = 0;
    int iso = 0;
    double focal = 0;      // mm
    int orientation = 1;   // 1 à 8 (TIFF)
};

namespace detail {
struct Reader {
    QByteArray tiff;
    bool little = true;
    quint16 u16(int at) const
    {
        if (at < 0 || at + 2 > tiff.size())
            return 0;
        const auto *p = reinterpret_cast<const uchar *>(tiff.constData() + at);
        return little ? qFromLittleEndian<quint16>(p) : qFromBigEndian<quint16>(p);
    }
    quint32 u32(int at) const
    {
        if (at < 0 || at + 4 > tiff.size())
            return 0;
        const auto *p = reinterpret_cast<const uchar *>(tiff.constData() + at);
        return little ? qFromLittleEndian<quint32>(p) : qFromBigEndian<quint32>(p);
    }
    // Entrée d'IFD : 12 octets (étiquette, type, nombre, valeur ou position).
    QString ascii(int entry) const
    {
        const quint32 count = u32(entry + 4);
        const int at = count <= 4 ? entry + 8 : int(u32(entry + 8));
        if (count == 0 || at < 0 || qint64(at) + count > tiff.size())
            return {};
        return QString::fromLatin1(tiff.mid(at, int(count))).remove(QChar(0)).trimmed();
    }
    double rational(int entry) const
    {
        const quint16 type = u16(entry + 2);
        if (type != 5 && type != 10)   // RATIONAL ou SRATIONAL uniquement
            return 0;
        const int at = int(u32(entry + 8));
        const quint32 den = u32(at + 4);
        return den ? double(u32(at)) / den : 0;
    }
    int number(int entry) const
    {
        return u16(entry + 2) == 3 ? u16(entry + 8) : int(u32(entry + 8));   // SHORT ou LONG
    }
};
}

// Segment APP1 « Exif\0\0 » d'un fichier JPEG.
inline QByteArray jpegExifBlock(const QByteArray &jpeg)
{
    if (!jpeg.startsWith("\xFF\xD8"))
        return {};
    int pos = 2;
    while (pos + 4 <= jpeg.size() && uchar(jpeg.at(pos)) == 0xFF) {
        const uchar marker = uchar(jpeg.at(pos + 1));
        const int length = (uchar(jpeg.at(pos + 2)) << 8) | uchar(jpeg.at(pos + 3));
        if (marker == 0xDA || length < 2)   // début de l'image : plus de métadonnées
            break;
        if (marker == 0xE1 && jpeg.mid(pos + 4, 6) == QByteArray("Exif\0\0", 6))
            return jpeg.mid(pos + 10, length - 8);
        pos += 2 + length;
    }
    return {};
}

inline Info parse(const QByteArray &tiff)
{
    Info info;
    detail::Reader r;
    r.tiff = tiff;
    if (tiff.startsWith("II"))
        r.little = true;
    else if (tiff.startsWith("MM"))
        r.little = false;
    else
        return info;
    if (r.u16(2) != 42)
        return info;
    int exifIfd = 0;
    QString dateTime, original;
    auto walk = [&](int ifd, auto &&self) -> void {
        const int n = r.u16(ifd);
        if (n <= 0 || n > 500)
            return;
        for (int i = 0; i < n; ++i) {
            const int e = ifd + 2 + i * 12;
            switch (r.u16(e)) {
            case 0x010F: info.make = r.ascii(e); break;
            case 0x0110: info.model = r.ascii(e); break;
            case 0x0112: info.orientation = qBound(1, r.number(e), 8); break;
            case 0x0132: dateTime = r.ascii(e); break;
            case 0x8769: exifIfd = int(r.u32(e + 8)); break;
            case 0x9003: original = r.ascii(e); break;
            case 0x829A: info.exposure = r.rational(e); break;
            case 0x829D: info.fNumber = r.rational(e); break;
            case 0x8827: info.iso = r.number(e); break;
            case 0x920A: info.focal = r.rational(e); break;
            }
        }
        Q_UNUSED(self);
    };
    walk(int(r.u32(4)), walk);
    if (exifIfd > 0 && exifIfd < tiff.size())
        walk(exifIfd, walk);
    // « 2026:08:14 18:42:07 »
    const QString when = original.isEmpty() ? dateTime : original;
    info.taken = QDateTime::fromString(when, QStringLiteral("yyyy:MM:dd HH:mm:ss"));
    // Le modèle répète souvent la marque (« Canon » + « Canon EOS 80D »).
    if (!info.make.isEmpty() && info.model.startsWith(info.make, Qt::CaseInsensitive))
        info.make.clear();
    info.valid = true;
    return info;
}

// « 1/640 s » ou « 2 s ».
inline QString exposureText(double seconds)
{
    if (seconds <= 0)
        return {};
    if (seconds >= 1)
        return QStringLiteral("%1 s").arg(seconds, 0, 'g', 3);
    return QStringLiteral("1/%1 s").arg(qRound(1.0 / seconds));
}

} // namespace Exif
