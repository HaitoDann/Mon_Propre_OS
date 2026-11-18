#pragma once
// Thème de fenêtre VinX (ADR 0024) : décoration Aurorae de KWin générée par programme, pour suivre
// le thème clair/sombre. Boutons « pastilles » à droite (réduire, agrandir, fermer), toujours en
// couleur sur la fenêtre active : orange, vert, rouge. Pure (sans E/S) : tests/tst_windowtheme.cpp.
#include <QByteArray>
#include <QColor>
#include <QMap>
#include <QString>

namespace windowtheme {

struct Colors {
    QColor accent{0x10, 0xDD, 0x8C};   // fermeture de la fenêtre active
    QColor accentInk{0x06, 0x13, 0x0D};
    bool dark = false;
};

// Dimensions (pixels logiques) : barre de titre de 40 px, pastilles de 14 px.
constexpr int titleHeight = 26, edgeTop = 7, edgeBottom = 7, bar = edgeTop + titleHeight + edgeBottom;
constexpr int buttonWidth = 26, buttonHeight = 26, radius = 10;

inline QString hex(const QColor &c) { return c.name(QColor::HexRgb).toUpper(); }

struct Palette {
    QString bar, border, text, textInactive, neutral, neutralInactive, glyph, accent, accentInk, danger;
    QString close, maximize, minimize, glyphOnColor;
};

inline Palette palette(const Colors &c)
{
    Palette p;
    p.bar = c.dark ? "#1A1C1B" : "#F8F7F4";
    p.border = c.dark ? "#2C302E" : "#DAD8D1";
    p.text = c.dark ? "#ECECEA" : "#141414";
    p.textInactive = c.dark ? "#7A7D7A" : "#8A8983";
    p.neutral = c.dark ? "#3A3E3C" : "#D2D0C9";
    p.neutralInactive = c.dark ? "#2C302E" : "#E3E1DB";
    p.glyph = c.dark ? "#ECECEA" : "#141414";
    p.accent = hex(c.accent);
    p.accentInk = hex(c.accentInk);
    p.danger = "#E5484D";
    // Pastilles (choix de l'utilisateur, ADR 0024) : fermer rouge, agrandir vert, réduire orange.
    p.close = "#FF5F57";
    p.maximize = "#28C840";
    p.minimize = "#FEBC2E";
    p.glyphOnColor = "#4D1F0C";   // pictogramme sombre et chaud, lisible sur les trois couleurs
    return p;
}

inline QString rgbTriplet(const QString &h)
{
    const QColor c(h);
    return QStringLiteral("%1,%2,%3").arg(c.red()).arg(c.green()).arg(c.blue());
}

// Cadre (9 morceaux) : coins supérieurs arrondis, contour d'un pixel.
inline QByteArray decorationSvg(const Palette &p)
{
    QString out = QStringLiteral("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"200\" height=\"200\">\n");
    // prefix "" = fenêtre active, "inactive-" = inactive ; même dessin (le titre change de couleur).
    // Les fenêtres agrandies (« maximized-* ») n'ont ni coins arrondis ni contour.
    const QString r = QString::number(radius), h = QString::number(bar);
    int y = 0;
    for (const QString &state : {QStringLiteral(""), QStringLiteral("inactive-")}) {
        const QString oy = QString::number(y);
        auto g = [&](const QString &id, const QString &body) {
            out += QStringLiteral("<g id=\"decoration-%1%2\" transform=\"translate(%3 %4)\">%5</g>\n")
                       .arg(state, id).arg(0).arg(oy).arg(body);
        };
        // Coin haut-gauche (12 × 40)
        g("topleft", QStringLiteral("<path d=\"M12,0H%1A%1,%1 0 0 0 0,%1V%2H12Z\" fill=\"%3\"/>"
                                    "<path d=\"M12,1H%1A%4,%4 0 0 0 1,%1V%2H12Z\" fill=\"%5\"/>")
                         .arg(r, h, p.border, QString::number(radius - 1), p.bar));
        g("top", QStringLiteral("<rect width=\"1\" height=\"1\" fill=\"%1\"/><rect y=\"1\" width=\"1\" height=\"%2\" fill=\"%3\"/>")
                     .arg(p.border, QString::number(bar - 1), p.bar));
        g("topright", QStringLiteral("<path d=\"M0,0H2A%1,%1 0 0 1 12,%1V%2H0Z\" fill=\"%3\"/>"
                                     "<path d=\"M0,1H2A%4,%4 0 0 1 11,%1V%2H0Z\" fill=\"%5\"/>")
                          .arg(r, h, p.border, QString::number(radius - 1), p.bar));
        for (const char *id : {"left", "right", "bottom", "bottomleft", "bottomright"})
            g(QString::fromLatin1(id), QStringLiteral("<rect width=\"1\" height=\"1\" fill=\"%1\"/>").arg(p.border));
        g("center", QStringLiteral("<rect width=\"1\" height=\"1\" fill=\"%1\"/>").arg(p.bar));
        // Fenêtre agrandie : barre pleine, sans contour.
        for (const char *id : {"maximized-topleft", "maximized-top", "maximized-topright"})
            g(QString::fromLatin1(id), QStringLiteral("<rect width=\"1\" height=\"%1\" fill=\"%2\"/>").arg(h, p.bar));
        g("maximized-center", QStringLiteral("<rect width=\"1\" height=\"1\" fill=\"%1\"/>").arg(p.bar));
        y += bar + 10;
    }
    out += QStringLiteral("</svg>\n");
    return out.toUtf8();
}

enum class Glyph { Close, Minimize, Maximize, Restore };

inline QString glyphPath(Glyph g)
{
    // Pictogrammes 6 × 6 centrés sur la pastille (13, 13).
    switch (g) {
    case Glyph::Close: return QStringLiteral("M10.5,10.5L15.5,15.5M15.5,10.5L10.5,15.5");
    case Glyph::Minimize: return QStringLiteral("M10,13H16");
    case Glyph::Maximize: return QStringLiteral("M13,10V16M10,13H16");
    case Glyph::Restore: return QStringLiteral("M10,13H16M13,10V16");
    }
    return {};
}

// Bouton : une pastille par état (Aurorae : préfixes active, hover, pressed, inactive, deactivated…).
inline QByteArray buttonSvg(const Palette &p, Glyph g)
{
    struct State { const char *name; QString fill; QString glyph; };
    const QString color = g == Glyph::Close ? p.close : (g == Glyph::Minimize ? p.minimize : p.maximize);
    // Enfoncée : même couleur, un peu plus sombre.
    const QString pressed = QColor(color).darker(115).name(QColor::HexRgb).toUpper();
    const QString glyph = p.glyphOnColor;
    const QList<State> states = {
        {"active", color, QString()},
        {"hover", color, glyph},
        {"pressed", pressed, glyph},
        {"inactive", p.neutralInactive, QString()},
        {"hover-inactive", color, glyph},
        {"pressed-inactive", pressed, glyph},
        {"deactivated", p.neutralInactive, QString()},
        {"deactivated-inactive", p.neutralInactive, QString()},
    };
    QString out = QStringLiteral("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%1\" height=\"%2\">\n")
                      .arg(buttonWidth * states.size()).arg(buttonHeight);
    int x = 0;
    for (const State &s : states) {
        QString body = QStringLiteral("<rect width=\"%1\" height=\"%2\" fill=\"none\"/>"
                                      "<circle cx=\"13\" cy=\"13\" r=\"7\" fill=\"%3\"/>")
                           .arg(buttonWidth).arg(buttonHeight).arg(s.fill);
        if (!s.glyph.isEmpty())
            body += QStringLiteral("<path d=\"%1\" fill=\"none\" stroke=\"%2\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\" opacity=\"0.75\"/>")
                        .arg(glyphPath(g), s.glyph);
        out += QStringLiteral("<g id=\"%1-center\" transform=\"translate(%2 0)\">%3</g>\n")
                   .arg(QString::fromLatin1(s.name)).arg(x).arg(body);
        x += buttonWidth;
    }
    out += QStringLiteral("</svg>\n");
    return out.toUtf8();
}

inline QByteArray rcFile(const Palette &p)
{
    QString s;
    s += QStringLiteral("[General]\n");
    s += QStringLiteral("ActiveTextColor=%1\nInactiveTextColor=%2\n").arg(rgbTriplet(p.text), rgbTriplet(p.textInactive));
    s += QStringLiteral("TitleAlignment=Center\nTitleVerticalAlignment=Center\nAnimation=120\n");
    s += QStringLiteral("UseTextShadow=false\nHaloActive=false\nHaloInactive=false\nShadow=true\n");
    s += QStringLiteral("DecorationPosition=0\n\n[Layout]\n");
    s += QStringLiteral("BorderLeft=1\nBorderRight=1\nBorderBottom=1\nBorderTop=0\n");
    s += QStringLiteral("TitleEdgeTop=%1\nTitleEdgeBottom=%2\nTitleEdgeLeft=12\nTitleEdgeRight=10\n").arg(edgeTop).arg(edgeBottom);
    s += QStringLiteral("TitleEdgeTopMaximized=%1\nTitleEdgeBottomMaximized=%2\nTitleEdgeLeftMaximized=12\nTitleEdgeRightMaximized=10\n")
             .arg(edgeTop).arg(edgeBottom);
    s += QStringLiteral("TitleBorderLeft=8\nTitleBorderRight=8\nTitleHeight=%1\n").arg(titleHeight);
    s += QStringLiteral("ButtonWidth=%1\nButtonHeight=%2\nButtonSpacing=2\nButtonMarginTop=0\nExplicitButtonSpacer=8\n")
             .arg(buttonWidth).arg(buttonHeight);
    s += QStringLiteral("PaddingTop=0\nPaddingBottom=0\nPaddingLeft=0\nPaddingRight=0\n");
    return s.toUtf8();
}

inline QByteArray metadataDesktop()
{
    return QByteArrayLiteral("[Desktop Entry]\nName=VinX\nComment=Fenêtres VinX OS (pastilles)\n"
                             "X-KDE-PluginInfo-Author=VinX OS\nX-KDE-PluginInfo-Name=VinX\n"
                             "X-KDE-PluginInfo-Version=1.0\nX-KDE-PluginInfo-License=GPL\n");
}

inline QByteArray metadataJson()
{
    return QByteArrayLiteral("{\n  \"KPlugin\": { \"Id\": \"VinX\", \"Name\": \"VinX\", \"Description\": \"Fenêtres VinX OS (pastilles)\","
                             " \"License\": \"GPL\", \"Version\": \"1.0\" }\n}\n");
}

// Fichiers du thème « VinX » (chemins relatifs au dossier aurorae/themes/VinX).
inline QMap<QString, QByteArray> themeFiles(const Colors &c)
{
    const Palette p = palette(c);
    return {
        {QStringLiteral("metadata.desktop"), metadataDesktop()},
        {QStringLiteral("metadata.json"), metadataJson()},
        {QStringLiteral("VinXrc"), rcFile(p)},
        {QStringLiteral("decoration.svg"), decorationSvg(p)},
        {QStringLiteral("close.svg"), buttonSvg(p, Glyph::Close)},
        {QStringLiteral("minimize.svg"), buttonSvg(p, Glyph::Minimize)},
        {QStringLiteral("maximize.svg"), buttonSvg(p, Glyph::Maximize)},
        {QStringLiteral("restore.svg"), buttonSvg(p, Glyph::Restore)},
    };
}

// Applications GTK à barre de titre intégrée (Firefox, Thunderbird…) : elles dessinent leurs propres
// boutons ; on leur donne les mêmes pastilles par la feuille de style utilisateur de GTK.
inline const char *gtkBlockBegin() { return "/* VinX : pastilles des fenêtres (début, géré par vinx-window-theme) */"; }
inline const char *gtkBlockEnd() { return "/* VinX : pastilles des fenêtres (fin) */"; }

inline QString gtkCss(const Colors &c)
{
    const Palette p = palette(c);
    return QStringLiteral(
        "%1\n"
        "headerbar button.titlebutton, .titlebar button.titlebutton, window.csd button.titlebutton {\n"
        "  min-width: 14px; min-height: 14px; padding: 0; margin: 0 4px; border: none; border-radius: 50%;\n"
        "  box-shadow: none; background-image: none; color: transparent; -gtk-icon-shadow: none;\n"
        "}\n"
        "button.titlebutton.minimize { background-color: %2; }\n"
        "button.titlebutton.maximize { background-color: %3; }\n"
        "button.titlebutton.close { background-color: %4; }\n"
        "button.titlebutton:hover, button.titlebutton:active { color: %5; }\n"
        "button.titlebutton:backdrop, button.titlebutton.minimize:backdrop, button.titlebutton.maximize:backdrop,\n"
        "button.titlebutton.close:backdrop { background-color: %6; color: transparent; }\n"
        "%7\n")
        .arg(QString::fromUtf8(gtkBlockBegin()), p.minimize, p.maximize, p.close, p.glyphOnColor, p.neutralInactive,
             QString::fromUtf8(gtkBlockEnd()));
}

// Remplace (ou ajoute) le bloc VinX dans une feuille gtk.css existante, sans toucher au reste
// (KDE y écrit ses propres règles de couleurs).
inline QString mergeGtkCss(const QString &existing, const QString &block)
{
    const QString begin = QString::fromUtf8(gtkBlockBegin()), end = QString::fromUtf8(gtkBlockEnd());
    const qsizetype a = existing.indexOf(begin);
    const qsizetype b = a >= 0 ? existing.indexOf(end, a) : -1;
    if (a >= 0 && b >= 0) {
        qsizetype after = b + end.size();
        if (after < existing.size() && existing.at(after) == QLatin1Char('\n'))
            ++after;
        return existing.left(a) + block + existing.mid(after);
    }
    QString out = existing;
    if (!out.isEmpty() && !out.endsWith(QLatin1Char('\n')))
        out += QLatin1Char('\n');
    return out + block;
}

} // namespace windowtheme
