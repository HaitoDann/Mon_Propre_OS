.pragma library
// Icônes VinX des applications connues : pictogramme du jeu VinX + teinte sobre.
// Les autres applications gardent l'icône de leur thème (image://theme/…).
const known = {
    "org.kde.dolphin":   { glyph: "folder",   tint: "#4C6FA8" },
    "firefox-esr":       { glyph: "globe",    tint: "#B8693F" },
    "firefox":           { glyph: "globe",    tint: "#B8693F" },
    "libreoffice-writer":{ glyph: "doc",      tint: "#4F60A3" },
    "libreoffice-calc":  { glyph: "table",    tint: "#3E8460" },
    "libreoffice-impress":{ glyph: "image",   tint: "#A8603F" },
    "thunderbird":       { glyph: "mail",     tint: "#3F7896" },
    "org.kde.discover":  { glyph: "bag",      tint: "#5B65C9" },
    "systemsettings":    { glyph: "sliders",  tint: "#5F6270" },
    "org.kde.konsole":   { glyph: "terminal", tint: "#2E3036" },
    "vlc":               { glyph: "music",    tint: "#A34E62" },
    "org.kde.gwenview":  { glyph: "image",    tint: "#9C5577" },
    "org.kde.okular":    { glyph: "doc",      tint: "#A88A3E" },
    "org.kde.kcalc":     { glyph: "equals",   tint: "#5F6270" },
    "org.vinx.gallery":  { glyph: "grid",     tint: "#5B65C9" },
    "org.vinx.settings": { glyph: "sliders",  tint: "#5F6270" },
    "org.vinx.store":    { glyph: "bag",      tint: "#5B65C9" },
    "org.vinx.welcome":  { glyph: "info",     tint: "#5B65C9" }
};

function forApp(appId) {
    return known[appId] || null;
}

// Applications épinglées par défaut (identifiants .desktop).
const defaultPinned = ["org.kde.dolphin", "firefox-esr", "libreoffice-writer", "libreoffice-calc",
                       "thunderbird", "org.vinx.store", "org.vinx.settings"];

// Préférence « liste » : QSettings peut renvoyer une chaîne seule pour une liste d'un élément.
function asList(v, fallback) {
    if (v === undefined || v === null || v === "") return fallback.slice();
    return Array.isArray(v) ? v.slice() : [String(v)];
}
