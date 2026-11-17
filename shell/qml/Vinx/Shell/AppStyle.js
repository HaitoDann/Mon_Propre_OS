.pragma library
// Seules les applications VinX et les outils système ont une icône VinX (tuile neutre,
// pictogramme à l'encre, point de couleur). Les applications tierces (Firefox, LibreOffice,
// Thunderbird…) gardent leur logo officiel, posé sur la même tuile neutre (ADR 0018).
const known = {
    "org.vinx.files":    { glyph: "folder",   tint: "#2F6FD0" },
    "org.vinx.settings": { glyph: "sliders",  tint: "#8A8983" },
    "org.vinx.store":    { glyph: "bag",      tint: "#10DD8C" },
    "org.vinx.welcome":  { glyph: "info",     tint: "#10DD8C" },
    "org.vinx.updates":  { glyph: "restart",  tint: "#10DD8C" },
    "org.vinx.gallery":  { glyph: "grid",     tint: "#10DD8C" },
    "systemsettings":    { glyph: "sliders",  tint: "#8A8983" },
    "org.vinx.terminal": { glyph: "terminal", tint: "#141414" },
    "org.kde.konsole":   { glyph: "terminal", tint: "#141414" }
};

function forApp(appId) {
    return known[appId] || null;
}

// Applications épinglées par défaut (identifiants .desktop).
const defaultPinned = ["org.vinx.files", "firefox-esr", "libreoffice-writer", "libreoffice-calc",
                       "thunderbird", "org.vinx.store", "org.vinx.settings"];

// Préférence « liste » : QSettings peut renvoyer une chaîne seule pour une liste d'un élément.
// Applications KDE remplacées par VinX (ADR 0025) : les épinglages existants suivent.
const replaced = { "org.kde.dolphin": "org.vinx.files",
                   "org.kde.discover": "org.vinx.store", "systemsettings": "org.vinx.settings" };
function asList(v, fallback) {
    if (v === undefined || v === null || v === "") return fallback.slice();
    const list = Array.isArray(v) ? v.slice() : [String(v)];
    const out = [];
    for (const id of list) {
        const r = replaced[id] || id;
        if (out.indexOf(r) < 0) out.push(r);
    }
    return out;
}

// Identifiant .desktop normalisé à partir de ce que fournit le gestionnaire de tâches :
// « org.vinx.store », « org.vinx.store.desktop », « applications:org.vinx.store.desktop »,
// ou un chemin « /usr/share/applications/org.vinx.store.desktop ».
function normalizeId(appId, launcherUrl) {
    let id = appId ? String(appId) : ""
    if (!id && launcherUrl) id = String(launcherUrl)
    id = id.replace(/^applications:/, "").replace(/^file:\/\//, "")
    id = id.split("/").pop()
    return id.replace(/\.desktop$/, "")
}
