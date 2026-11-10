// Registre des applications (futur : fichiers .desktop + métadonnées AppStream).
const APPS = [
  { id: "files",    name: "Fichiers",   glyph: "folder",   colors: ["#5075B2", "#4C6FA8"] },
  { id: "firefox",  name: "Firefox",    glyph: "globe",    colors: ["#C36F42", "#B8693F"] },
  { id: "writer",   name: "Documents",  glyph: "doc",      colors: ["#5365AC", "#4F60A3"] },
  { id: "calc",     name: "Tableur",    glyph: "table",    colors: ["#418B65", "#3E8460"] },
  { id: "mail",     name: "Courrier",   glyph: "mail",     colors: ["#427F9F", "#3F7896"] },
  { id: "calendar", name: "Calendrier", glyph: "calendar", colors: ["#B25553", "#A8514F"] },
  { id: "store",    name: "Store",      glyph: "bag",      colors: ["#606BD5", "#5B65C9"] },
  { id: "settings", name: "Paramètres", glyph: "sliders",  colors: ["#646776", "#5F6270"] },
  { id: "terminal", name: "Terminal",   glyph: "terminal", colors: ["#303239", "#2E3036"] },
  { id: "notes",    name: "Notes",      glyph: "note",     colors: ["#B29241", "#A88A3E"] },
  { id: "photos",   name: "Photos",     glyph: "image",    colors: ["#A55A7E", "#9C5577"] },
  { id: "music",    name: "Musique",    glyph: "music",    colors: ["#AC5267", "#A34E62"] },
  { id: "help",     name: "Aide",       glyph: "info",     colors: ["#646776", "#5F6270"] },
];
const appById = (id) => APPS.find((a) => a.id === id);

// Menus d'application génériques affichés dans la barre supérieure.
const APP_MENUS = ["Fichier", "Édition", "Affichage", "Fenêtre", "Aide"];

// Raccourcis clavier (source unique : menus, aide, documentation).
const SHORTCUTS = [
  ["Ctrl + Espace", "Recherche globale"],
  ["F3  ou  Ctrl + Alt + ↑", "Vue d'ensemble (Exposé)"],
  ["Ctrl + Alt + ← / →", "Espace de travail précédent / suivant"],
  ["Ctrl + Alt + Maj + ← / →", "Déplacer la fenêtre vers l'espace voisin"],
  ["Ctrl + Maj + ← / →", "Placer la fenêtre à gauche / à droite"],
  ["Ctrl + Maj + ↑", "Agrandir / restaurer la fenêtre"],
  ["Ctrl + Maj + ↓", "Réduire la fenêtre"],
  ["Ctrl + Maj + F", "Plein écran"],
  ["Ctrl + Maj + G", "Organiser les fenêtres"],
  ["Ctrl + W", "Fermer la fenêtre"],
  ["Échap", "Fermer un panneau, quitter le plein écran ou l'Exposé"],
];

// Fichiers fictifs pour la recherche globale.
const FILES = [
  { name: "Rapport annuel 2026.odt", where: "Documents", app: "writer", glyph: "doc" },
  { name: "Budget prévisionnel.ods", where: "Documents", app: "calc", glyph: "table" },
  { name: "Présentation client.pdf", where: "Téléchargements", app: "files", glyph: "doc" },
  { name: "Notes de réunion.txt", where: "Documents", app: "notes", glyph: "note" },
  { name: "Vacances été.jpg", where: "Images", app: "photos", glyph: "image" },
  { name: "Contrat prestataire.pdf", where: "Documents", app: "files", glyph: "doc" },
];

const WALLPAPERS = {
  graphite: { name: "Graphite", file: "../branding/wallpaper/vinx-graphite.svg" },
  nebula: { name: "Nebula", file: "../branding/wallpaper/vinx-nebula.svg" },
  minimal: { name: "Nebula épuré", file: "../branding/wallpaper/vinx-nebula-minimal.svg" },
};
const wallpaperUrl = (key) => new URL((WALLPAPERS[key] || WALLPAPERS.graphite).file, location.href).href;

const sw = (attr, on) => `<label class="switch"><input type="checkbox" ${attr} ${on ? "checked" : ""}><span></span></label>`;

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
        ["Pack Développement", "terminal", ["#33353B", "#2E3036"], "Codium, Git, Docker"],
        ["Pack Gaming", "globe", ["#42895F", "#3E8460"], "Steam, Lutris, Heroic"],
        ["Pack Multimédia", "music", ["#A55A7E", "#9C5577"], "VLC, Kdenlive, OBS"],
        ["Pack Graphisme", "image", ["#C36F43", "#B8693F"], "GIMP, Inkscape, Krita"],
        ["LibreOffice", "doc", ["#5465AD", "#4F60A3"], "Suite bureautique"],
        ["Thunderbird", "mail", ["#437F9F", "#3F7896"], "Messagerie"],
      ];
      return `<div class="store-cats">${["À la une", "Packs", "Bureautique", "Développement", "Jeux", "Multimédia"].map((c, i) => `<button class="chip ${i ? "" : "on"}" data-chip>${c}</button>`).join("")}</div>
        <div class="store-grid">${items.map(([n, g, c, d]) => `<div class="card">${appIcon({ glyph: g, colors: c })}<div><b>${n}</b><small>${d}</small></div><button class="btn primary" data-install="${n}">Obtenir</button></div>`).join("")}</div>`;
    }
    case "settings": {
      const s = Shell.state;
      return `<div class="settings">
        <section><h4>Apparence</h4>
          <div class="settings-row"><span>Thème</span><div class="seg" data-theme-seg><button data-v="light">Clair</button><button data-v="dark">Sombre</button></div></div>
          <div class="settings-row"><span>Couleur d'accent</span><div class="swatches">${["#5B65C9", "#3B82C4", "#3E8460", "#B8693F", "#A8514F", "#6B6E76"].map((c) => `<button class="sw" style="background:${c}" data-accent="${c}" aria-label="${c}"></button>`).join("")}</div></div>
        </section>
        <section><h4>Fond d'écran</h4>
          <div class="wall-choices">${Object.entries(WALLPAPERS).map(([k, w]) => `<button class="wall" data-wallpaper="${k}"><span style="background-image:url('${wallpaperUrl(k)}')"></span>${w.name}</button>`).join("")}</div>
        </section>
        <section><h4>Bureau</h4>
          <div class="settings-row"><span>Widget Horloge</span>${sw('data-widget="clock"', s.widgets.clock)}</div>
          <div class="settings-row"><span>Widget Agenda</span>${sw('data-widget="agenda"', s.widgets.agenda)}</div>
          <div class="settings-row"><span>Widget Note rapide</span>${sw('data-widget="note"', s.widgets.note)}</div>
        </section>
        <section><h4>Dock</h4>
          <div class="settings-row"><span>Taille des icônes</span><input class="range small" type="range" min="36" max="64" value="${s.dockSize}" data-dock-size></div>
          <div class="settings-row"><span>Agrandissement au survol</span>${sw("data-magnify", s.magnify)}</div>
        </section>
        <section><h4>Maquette</h4>
          <div class="settings-row"><span>Réinitialiser les préférences</span><button class="btn" data-reset>Réinitialiser</button></div>
        </section></div>`;
    }
    case "help":
      return `<h3 style="margin-top:0">Raccourcis clavier</h3>
        <div class="shortcuts">${SHORTCUTS.map(([k, d]) => `<kbd>${k}</kbd><span>${d}</span>`).join("")}</div>
        <p class="placeholder">Astuce : faites glisser une fenêtre contre un bord ou un coin de l'écran pour l'aligner, ou vers le haut pour l'agrandir. Clic droit sur le bureau pour les widgets.</p>`;
    default:
      return `<p class="placeholder">${app.name} — application de démonstration.</p>`;
  }
}
