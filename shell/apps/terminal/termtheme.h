#pragma once
// Terminal VinX (toujours sombre) : couleurs (schémas au format Konsole lus par QTermWidget) et préférences VinX.
// Pur (sans QTermWidget) : testé par tests/tst_termtheme.cpp.
#include "vinxtokens.h"

#include <QColor>
#include <QSettings>
#include <QString>
#include <QStringList>

namespace termtheme {

struct Appearance {
    bool dark = false;
    QString accent = QString::fromLatin1(vinx::tokens::accents[0].fill);
    QString accentInk = QString::fromLatin1(vinx::tokens::accents[0].ink);
};

// Préférences VinX (~/.config/vinx/shell.ini). « auto » : l'accent résolu par le shell.
inline Appearance readAppearance(const QString &iniPath)
{
    QSettings s(iniPath, QSettings::IniFormat);
    Appearance a;
    a.dark = s.value(QStringLiteral("appearance/dark"), false).toString() == QLatin1String("true");
    QString id = s.value(QStringLiteral("appearance/accent")).toString();
    if (id == QLatin1String("auto"))
        id = s.value(QStringLiteral("appearance/resolvedAccent")).toString();
    for (const auto &acc : vinx::tokens::accents)
        if (id == QLatin1String(acc.id)) {
            a.accent = QString::fromLatin1(acc.fill);
            a.accentInk = QString::fromLatin1(acc.ink);
        }
    return a;
}

inline QString schemeName(bool dark) { return dark ? QStringLiteral("VinX-sombre") : QStringLiteral("VinX-clair"); }

// 16 couleurs ANSI (normales puis intenses), lisibles sur le fond de chaque thème.
inline QStringList ansi(bool dark)
{
    if (dark)
        return {"#1E2120", "#E5484D", "#3FA66B", "#D4A13C", "#4C8DF0", "#D95C9E", "#2BB5B5", "#C9C7C0",
                "#5F625F", "#FF6B6F", "#5CD08A", "#F0C060", "#7FB3FF", "#F08AC0", "#5AD8D8", "#FFFFFF"};
    return {"#141414", "#C23B40", "#1E7A47", "#8A5A00", "#1F5FB8", "#A33A78", "#0A7070", "#8A8983",
            "#5F5E5A", "#E5484D", "#2E9A5E", "#B07A10", "#2E7BE0", "#C2559A", "#16908F", "#C9C7C0"};
}

inline QString rgb(const QString &hex)
{
    const QColor c(hex);
    return QStringLiteral("%1,%2,%3").arg(c.red()).arg(c.green()).arg(c.blue());
}

// Schéma de couleurs au format .colorscheme (Konsole / QTermWidget).
inline QString colorScheme(bool dark)
{
    const QString bg = QString::fromLatin1(vinx::tokens::surfaceWindow[dark ? 0 : 1]).left(7);
    const QString fg = QString::fromLatin1(vinx::tokens::text[dark ? 0 : 1]).left(7);
    const QStringList c = ansi(dark);
    QString s;
    auto section = [&s](const QString &name, const QString &hex, bool bold = false) {
        s += QStringLiteral("[%1]\nColor=%2\nTransparency=false\nBold=%3\n\n").arg(name, rgb(hex), bold ? "true" : "false");
    };
    section(QStringLiteral("Background"), bg);
    section(QStringLiteral("BackgroundIntense"), bg);
    section(QStringLiteral("Foreground"), fg);
    section(QStringLiteral("ForegroundIntense"), fg, true);
    for (int i = 0; i < 8; ++i) {
        section(QStringLiteral("Color%1").arg(i), c[i]);
        section(QStringLiteral("Color%1Intense").arg(i), c[i + 8], true);
    }
    s += QStringLiteral("[General]\nDescription=%1\nOpacity=1\n").arg(dark ? "VinX sombre" : "VinX clair");
    return s;
}

} // namespace termtheme
