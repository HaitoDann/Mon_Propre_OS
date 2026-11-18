#pragma once

// Visionneur d'images VinX (ADR 0038) : retouches simples, testées dans tests/tst_viewer.cpp.
// Ordre d'application : rotation et miroir → recadrage → lumière → annotations → réduction.

#include <QImage>
#include <QRegularExpression>
#include <functional>
#include <QRectF>
#include <QTransform>
#include <QtMath>

#include "captureutil.h"

namespace Photo {

struct Edits {
    int quarterTurns = 0;      // sens des aiguilles d'une montre
    bool mirror = false;
    QRectF crop;               // fraction de l'image pivotée (vide = tout)
    int brightness = 0;        // −100 … 100
    int contrast = 0;          // −100 … 100
    QList<Capture::Shape> shapes;  // en pixels de l'image recadrée
    int maxSide = 0;           // 0 = taille d'origine ; 1600 pour un mail

    bool isIdentity() const
    {
        return quarterTurns % 4 == 0 && !mirror && crop.isEmpty() && brightness == 0 && contrast == 0 && shapes.isEmpty() && maxSide == 0;
    }
};

// Orientation EXIF (1 à 8) → image droite, comme l'affiche un téléphone.
inline QImage applyOrientation(const QImage &image, int orientation)
{
    QTransform t;
    bool flip = false;
    switch (orientation) {
    case 2: flip = true; break;
    case 3: t.rotate(180); break;
    case 4: t.rotate(180); flip = true; break;
    case 5: t.rotate(90); flip = true; break;
    case 6: t.rotate(90); break;
    case 7: t.rotate(270); flip = true; break;
    case 8: t.rotate(270); break;
    default: break;
    }
    QImage out = t.isIdentity() ? image : image.transformed(t);
    return flip ? out.mirrored(true, false) : out;
}

inline QImage rotated(const QImage &image, int quarterTurns, bool mirror)
{
    const int q = ((quarterTurns % 4) + 4) % 4;
    QImage out = image;
    if (q) {
        QTransform t;
        t.rotate(90.0 * q);
        out = image.transformed(t);
    }
    return mirror ? out.mirrored(true, false) : out;
}

inline QRect cropRect(const QSize &size, const QRectF &fraction)
{
    if (fraction.isEmpty())
        return QRect(QPoint(), size);
    const QRectF f = fraction.intersected(QRectF(0, 0, 1, 1));
    return QRectF(f.x() * size.width(), f.y() * size.height(), f.width() * size.width(), f.height() * size.height())
        .toAlignedRect().intersected(QRect(QPoint(), size));
}

// Luminosité : décalage ; contraste : pente autour du gris moyen. Table de 256 valeurs.
inline void adjust(QImage &image, int brightness, int contrast)
{
    if (brightness == 0 && contrast == 0)
        return;
    const double slope = contrast >= 0 ? 1.0 + contrast / 50.0 : 1.0 + contrast / 120.0;
    const double offset = brightness * 1.28;
    uchar table[256];
    for (int v = 0; v < 256; ++v)
        table[v] = uchar(qBound(0.0, (v - 128.0) * slope + 128.0 + offset, 255.0));
    image = image.convertToFormat(QImage::Format_ARGB32);
    for (int y = 0; y < image.height(); ++y) {
        auto *line = reinterpret_cast<QRgb *>(image.scanLine(y));
        for (int x = 0; x < image.width(); ++x) {
            const QRgb p = line[x];
            line[x] = qRgba(table[qRed(p)], table[qGreen(p)], table[qBlue(p)], qAlpha(p));
        }
    }
}

inline QImage apply(const QImage &source, const Edits &e)
{
    QImage out = rotated(source, e.quarterTurns, e.mirror);
    if (!e.crop.isEmpty())
        out = out.copy(cropRect(out.size(), e.crop));
    adjust(out, e.brightness, e.contrast);
    if (!e.shapes.isEmpty())
        out = Capture::render(out, e.shapes);
    if (e.maxSide > 0 && qMax(out.width(), out.height()) > e.maxSide)
        out = out.scaled(e.maxSide, e.maxSide, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    return out;
}

// « Plage.jpg » → « Plage (modifiée).jpg », puis « (modifiée 2) »… si le nom est pris.
inline QString copyName(const QString &baseName, const QString &suffix, const QString &tag, const std::function<bool(const QString &)> &exists)
{
    for (int i = 1; i < 1000; ++i) {
        const QString label = i == 1 ? tag : QStringLiteral("%1 %2").arg(tag).arg(i);
        const QString name = QStringLiteral("%1 (%2).%3").arg(baseName, label, suffix);
        if (!exists(name))
            return name;
    }
    return {};
}

// Ordre naturel des noms de fichiers (« 2 » avant « 10 »), indépendant de la langue du système.
inline bool naturalLess(const QString &a, const QString &b)
{
    int i = 0, j = 0;
    while (i < a.size() && j < b.size()) {
        if (a.at(i).isDigit() && b.at(j).isDigit()) {
            int ei = i, ej = j;
            while (ei < a.size() && a.at(ei).isDigit()) ++ei;
            while (ej < b.size() && b.at(ej).isDigit()) ++ej;
            const QString na = a.mid(i, ei - i).remove(QRegularExpression(QStringLiteral("^0+(?=\\d)")));
            const QString nb = b.mid(j, ej - j).remove(QRegularExpression(QStringLiteral("^0+(?=\\d)")));
            if (na.size() != nb.size())
                return na.size() < nb.size();
            if (na != nb)
                return na < nb;
            i = ei;
            j = ej;
            continue;
        }
        const int c = QString::compare(a.mid(i, 1), b.mid(j, 1), Qt::CaseInsensitive);
        if (c != 0)
            return a.at(i).toLower() < b.at(j).toLower();
        ++i;
        ++j;
    }
    return a.size() - i < b.size() - j;
}

} // namespace Photo
