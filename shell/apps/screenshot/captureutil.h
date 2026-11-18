#pragma once

// Capture d'écran VinX (ADR 0036) : fonctions pures, testées dans tests/tst_screenshot.cpp.
// - image brute renvoyée par KWin (interface org.kde.KWin.ScreenShot2) ;
// - nom du fichier enregistré ;
// - rendu des annotations (flèche, cadre, surlignage, flou, texte) en pleine résolution.

#include <QDateTime>
#include <QFont>
#include <QImage>
#include <QLineF>
#include <QPainter>
#include <QPainterPath>
#include <QRectF>
#include <QVariantMap>
#include <QtMath>

namespace Capture {

// Résultat de KWin : { type: "raw", width, height, stride, format (QImage::Format), scale }.
inline QImage imageFromRaw(const QByteArray &data, const QVariantMap &meta)
{
    const int width = meta.value(QStringLiteral("width")).toInt();
    const int height = meta.value(QStringLiteral("height")).toInt();
    const int stride = meta.value(QStringLiteral("stride")).toInt();
    const auto format = QImage::Format(meta.value(QStringLiteral("format"), int(QImage::Format_ARGB32)).toInt());
    if (width <= 0 || height <= 0 || stride < width || qint64(stride) * height > data.size()
        || format <= QImage::Format_Invalid || format >= QImage::NImageFormats)
        return {};
    // Copie : les octets appartiennent au tampon lu dans le tube.
    QImage image = QImage(reinterpret_cast<const uchar *>(data.constData()), width, height, stride, format).copy();
    const double scale = meta.value(QStringLiteral("scale"), 1.0).toDouble();
    if (scale > 0)
        image.setDevicePixelRatio(scale);
    return image;
}

// « Capture du 2026-11-18 à 10.42.15.png » (pas de « : », interdit sous Windows et sur clé FAT).
inline QString fileName(const QDateTime &when, const QString &pattern)
{
    return pattern.arg(when.toString(QStringLiteral("yyyy-MM-dd")), when.toString(QStringLiteral("HH.mm.ss"))) + QStringLiteral(".png");
}

// Annotation, en pixels de l'image d'origine.
struct Shape {
    enum Kind { Arrow, Frame, Highlight, Blur, Text };
    Kind kind = Arrow;
    QPointF from, to;
    QColor color = QColor(0xFF, 0x5F, 0x57);
    QString text;
};

inline Shape shapeFromMap(const QVariantMap &m)
{
    static const QStringList kinds = {QStringLiteral("arrow"), QStringLiteral("frame"), QStringLiteral("highlight"),
                                      QStringLiteral("blur"), QStringLiteral("text")};
    Shape s;
    s.kind = Shape::Kind(qMax(0, kinds.indexOf(m.value(QStringLiteral("kind")).toString())));
    s.from = QPointF(m.value(QStringLiteral("x1")).toDouble(), m.value(QStringLiteral("y1")).toDouble());
    s.to = QPointF(m.value(QStringLiteral("x2")).toDouble(), m.value(QStringLiteral("y2")).toDouble());
    s.color = QColor(m.value(QStringLiteral("color"), QStringLiteral("#FF5F57")).toString());
    s.text = m.value(QStringLiteral("text")).toString();
    return s;
}

// Épaisseur des traits proportionnelle à la taille de l'image (lisible une fois réduite).
inline qreal strokeFor(const QImage &image)
{
    return qMax(3.0, qMin(image.width(), image.height()) / 220.0);
}

// Flou par pixellisation : irréversible, contrairement à un flou gaussien léger.
inline void pixelate(QImage &image, const QRect &area, int block)
{
    const QRect r = area.normalized().intersected(image.rect());
    if (r.width() < 2 || r.height() < 2)
        return;
    const QImage small = image.copy(r).scaled(qMax(1, r.width() / block), qMax(1, r.height() / block), Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    QPainter p(&image);
    p.drawImage(r, small.scaled(r.size(), Qt::IgnoreAspectRatio, Qt::FastTransformation));
}

inline QImage render(const QImage &source, const QList<Shape> &shapes)
{
    QImage out = source.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    const qreal dpr = source.devicePixelRatio();
    out.setDevicePixelRatio(1.0);
    const qreal stroke = strokeFor(out);
    for (const Shape &s : shapes) {
        const QRectF rect = QRectF(s.from, s.to).normalized();
        if (s.kind == Shape::Blur) {
            pixelate(out, rect.toAlignedRect(), qMax(8, int(stroke * 4)));
            continue;
        }
        QPainter p(&out);
        p.setRenderHint(QPainter::Antialiasing);
        switch (s.kind) {
        case Shape::Arrow: {
            const QLineF line(s.from, s.to);
            if (line.length() < 1)
                break;
            const qreal head = stroke * 5;
            const qreal angle = qDegreesToRadians(line.angle());
            const QPointF tip = s.to;
            const QPointF left = tip + QPointF(-qCos(angle - M_PI / 7) * head, qSin(angle - M_PI / 7) * head);
            const QPointF right = tip + QPointF(-qCos(angle + M_PI / 7) * head, qSin(angle + M_PI / 7) * head);
            p.setPen(QPen(s.color, stroke, Qt::SolidLine, Qt::RoundCap));
            p.drawLine(QLineF(s.from, (left + right) / 2));
            QPainterPath headPath;
            headPath.moveTo(tip);
            headPath.lineTo(left);
            headPath.lineTo(right);
            headPath.closeSubpath();
            p.fillPath(headPath, s.color);
            break;
        }
        case Shape::Frame:
            p.setPen(QPen(s.color, stroke, Qt::SolidLine, Qt::SquareCap, Qt::RoundJoin));
            p.drawRoundedRect(rect, stroke, stroke);
            break;
        case Shape::Highlight: {
            QColor c = s.color;
            c.setAlphaF(0.38);
            p.setCompositionMode(QPainter::CompositionMode_Multiply);
            p.fillRect(rect, c);
            break;
        }
        case Shape::Text: {
            QFont f(QStringLiteral("IBM Plex Sans"));
            f.setPixelSize(int(stroke * 7));
            f.setWeight(QFont::DemiBold);
            p.setFont(f);
            // Contour clair autour du texte : lisible sur fond sombre comme clair.
            QPainterPath path;
            path.addText(s.from, f, s.text);
            p.setPen(QPen(QColor(255, 255, 255, 220), stroke, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
            p.drawPath(path);
            p.fillPath(path, s.color);
            break;
        }
        case Shape::Blur:
            break;
        }
    }
    out.setDevicePixelRatio(dpr);
    return out;
}

} // namespace Capture
