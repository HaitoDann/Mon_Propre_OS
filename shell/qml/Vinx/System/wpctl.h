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

#include <QVariantList>
#include <QVariantMap>

// Sorties audio (« Sinks ») de la section Audio de « wpctl status » :
//  │  *   47. Haut-parleurs intégrés               [vol: 0.40]
//  │      52. HDMI / DisplayPort 1                 [vol: 1.00]
inline QVariantList parseWpctlSinks(const QString &status)
{
    static const QRegularExpression line(QStringLiteral("^[\\s│├└─]*(\\*)?\\s*(\\d+)\\.\\s+(.+?)\\s*(\\[vol:[^\\]]*\\])?\\s*$"));
    QVariantList sinks;
    bool inAudio = false, inSinks = false;
    for (const QString &raw : status.split(QLatin1Char('\n'))) {
        const QString t = raw.trimmed();
        if (t == QLatin1String("Audio")) { inAudio = true; continue; }
        if (t == QLatin1String("Video") || t == QLatin1String("Settings")) { inAudio = false; inSinks = false; continue; }
        if (!inAudio)
            continue;
        if (t.contains(QLatin1String("Sinks:"))) { inSinks = true; continue; }
        if (inSinks && (t.startsWith(QStringLiteral("├─")) || t.startsWith(QStringLiteral("└─")))) { inSinks = false; continue; }
        if (!inSinks)
            continue;
        const auto m = line.match(raw);
        if (!m.hasMatch())
            continue;
        sinks.append(QVariantMap{{QStringLiteral("id"), m.captured(2).toInt()},
                                 {QStringLiteral("name"), m.captured(3).trimmed()},
                                 {QStringLiteral("isDefault"), !m.captured(1).isEmpty()}});
    }
    return sinks;
}
