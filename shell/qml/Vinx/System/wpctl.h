#pragma once

#include <QRegularExpression>
#include <QString>

// Analyse la sortie de « wpctl get-volume » (PipeWire / WirePlumber), ex. « Volume: 0.60 [MUTED] ».
struct WpctlVolume {
    bool ok = false;
    double volume = 0;
    bool muted = false;
};

inline WpctlVolume parseWpctlVolume(const QString &output)
{
    static const QRegularExpression re(QStringLiteral("Volume:\\s*([0-9]*\\.?[0-9]+)"));
    WpctlVolume v;
    const auto m = re.match(output);
    if (!m.hasMatch())
        return v;
    v.ok = true;
    v.volume = m.captured(1).toDouble();
    v.muted = output.contains(QLatin1String("[MUTED]"));
    return v;
}
