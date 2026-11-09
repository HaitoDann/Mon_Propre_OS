// Registre des applications (futur : fichiers .desktop + AppStream).
const APPS = [
  { id: "files",    name: "Fichiers",   glyph: "folder",   colors: ["#4F8BFF", "#2F5BEA"] },
  { id: "firefox",  name: "Firefox",    glyph: "globe",    colors: ["#FF9A3C", "#E8492F"] },
  { id: "writer",   name: "Documents",  glyph: "doc",      colors: ["#5B8DEF", "#3753C9"] },
  { id: "calc",     name: "Tableur",    glyph: "table",    colors: ["#34C47C", "#14915A"] },
  { id: "mail",     name: "Courrier",   glyph: "mail",     colors: ["#3EC5F2", "#1D8FD6"] },
  { id: "calendar", name: "Calendrier", glyph: "calendar", colors: ["#FF6B6B", "#D83A4F"] },
  { id: "store",    name: "Store",      glyph: "bag",      colors: ["#9B7BFF", "#6A3FE0"] },
  { id: "settings", name: "Paramètres", glyph: "sliders",  colors: ["#8A93A6", "#565E70"] },
  { id: "terminal", name: "Terminal",   glyph: "terminal", colors: ["#3A3F4E", "#1C1F28"] },
  { id: "notes",    name: "Notes",      glyph: "note",     colors: ["#FFD15C", "#F0A62A"] },
  { id: "photos",   name: "Photos",     glyph: "image",    colors: ["#F77FB8", "#D9468F"] },
  { id: "music",    name: "Musique",    glyph: "music",    colors: ["#FF6F8E", "#E03A62"] },
];
const appById = (id) => APPS.find((a) => a.id === id);

// Applications épinglées dans le dock (modifiable par clic droit).
let PINNED = ["files", "firefox", "writer", "calc", "mail", "calendar", "store", "settings"];

// Menus d'application génériques affichés dans la barre supérieure.
const APP_MENUS = ["Fichier", "Édition", "Affichage", "Fenêtre", "Aide"];

// Contenu des fenêtres de démonstration.
function appContent(app) {
  switch (app.id) {
    case "firefox":
      return `<div class="browser-bar">${icon("chevronL")}${icon("chevronR")}<input value="https://www.debian.org"></div>
        <div class="hero"><h1>Bienvenue</h1><p>Firefox ESR est préinstallé et prêt à l'emploi.</p></div>`;
    case "files":
      return `<div class="files">${[["folder","Documents"],["folder","Téléchargements"],["folder","Images"],["folder","Musique"],["doc","Rapport.odt"],["table","Budget.ods"],["image","Vacances.jpg"],["doc","Guide.pdf"]]
        .map(([g, n]) => `<div class="file">${icon(g)}${n}</div>`).join("")}</div>`;
    case "store": {
      const items = [
        ["Pack Développement", "terminal", ["#3A3F4E", "#1C1F28"], "Codium, Git, Docker"],
        ["Pack Gaming", "globe", ["#34C47C", "#14915A"], "Steam, Lutris, Heroic"],
        ["Pack Multimédia", "music", ["#F77FB8", "#D9468F"], "VLC, Kdenlive, OBS"],
        ["Pack Graphisme", "image", ["#FF9A3C", "#E8492F"], "GIMP, Inkscape, Krita"],
        ["LibreOffice", "doc", ["#5B8DEF", "#3753C9"], "Suite bureautique"],
        ["Thunderbird", "mail", ["#3EC5F2", "#1D8FD6"], "Messagerie"],
      ];
      return `<div class="store-cats">${["À la une", "Packs", "Bureautique", "Développement", "Jeux", "Multimédia"].map((c, i) => `<button class="chip ${i ? "" : "on"}" data-chip>${c}</button>`).join("")}</div>
        <div class="store-grid">${items.map(([n, g, c, d]) => `<div class="card">${appIcon({ glyph: g, colors: c })}<div><b>${n}</b><small>${d}</small></div><button class="btn primary" data-install="${n}">Obtenir</button></div>`).join("")}</div>`;
    }
    case "settings":
      return `<h3 style="margin-top:0">Apparence</h3>
        <div class="settings-row"><span>Thème</span><div class="seg" data-theme-seg><button data-v="light">Clair</button><button data-v="dark">Sombre</button></div></div>
        <div class="settings-row"><span>Couleur d'accent</span><div class="swatches">${["#A855F7", "#6366F1", "#EC4899", "#F97316", "#16A34A", "#0EA5E9"].map((c) => `<button class="sw" style="background:${c}" data-accent="${c}"></button>`).join("")}</div></div>`;
    default:
      return `<p class="placeholder">${app.name} — application de démonstration.</p>`;
  }
}
