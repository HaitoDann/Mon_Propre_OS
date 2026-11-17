#pragma once
// Choix automatique de la couleur d'accent d'après une image (ADR 0021).
// Analyse pure, sans E/S : testée par tests/tst_accentpick.cpp.
#include <QColor>
#include <QImage>
#include <QList>
#include <QString>
#include <algorithm>
#include <cmath>

namespace accentpick {

struct Candidate {
    QString id;
    QColor fill;
};

// Teinte dominante pondérée par la saturation et la luminosité des pixels ; -1 si l'image est terne.
inline double dominantHue(const QImage &source)
{
    if (source.isNull())
        return -1;
    const QImage img = source.scaled(64, 64, Qt::IgnoreAspectRatio, Qt::SmoothTransformation).convertToFormat(QImage::Format_RGB32);
    constexpr int bins = 36;   // tranches de 10°
    double hist[bins] = {};
    double colorful = 0, total = 0;
    for (int y = 0; y < img.height(); ++y) {
        const QRgb *line = reinterpret_cast<const QRgb *>(img.constScanLine(y));
        for (int x = 0; x < img.width(); ++x) {
            const QColor c = QColor::fromRgb(line[x]);
            const double s = c.hsvSaturationF(), v = c.valueF();
            total += 1;
            if (s < 0.25 || v < 0.2)
                continue;
            const double w = s * v;
            colorful += w;
            hist[std::clamp(int(c.hsvHueF() * bins), 0, bins - 1)] += w;
        }
    }
    if (total == 0 || colorful / total < 0.04)
        return -1;
    // Pic lissé sur trois tranches voisines.
    int best = 0;
    double bestScore = -1;
    for (int i = 0; i < bins; ++i) {
        const double score = hist[(i + bins - 1) % bins] + 2 * hist[i] + hist[(i + 1) % bins];
        if (score > bestScore) {
            bestScore = score;
            best = i;
        }
    }
    return (best + 0.5) * 360.0 / bins;
}

inline double hueDistance(double a, double b)
{
    const double d = std::fabs(a - b);
    return std::min(d, 360.0 - d);
}

// Identifiant de l'accent dont la teinte est la plus proche ; « neutral » si l'image est terne.
inline QString pick(const QImage &image, const QList<Candidate> &candidates, const QString &neutral)
{
    const double hue = dominantHue(image);
    if (hue < 0)
        return neutral;
    QString best = neutral;
    double bestDistance = 1e9;
    for (const Candidate &c : candidates) {
        if (c.id == neutral || c.fill.hsvSaturationF() < 0.25)
            continue;
        const double d = hueDistance(hue, c.fill.hsvHueF() * 360.0);
        if (d < bestDistance) {
            bestDistance = d;
            best = c.id;
        }
    }
    return best;
}

} // namespace accentpick
