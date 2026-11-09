// Registre des applications (futur : fichiers .desktop + métadonnées AppStream).
const APPS = [
  { id: "files",    name: "Fichiers",   glyph: "folder",   colors: ["#4F8BFF", "#2F5BEA"] },
  { id: "firefox",  name: "Firefox",    glyph: "globe",    colors: ["#FF9A3C", "#E8492F"] },
  { id: "writer",   name: "Documents",  glyph: "doc",      colors: ["#5B8DEF", "#3753C9"] },
  { id: "calc",     name: "Tableur",    glyph: "table",    colors: ["#34C47C", "#14915A"] },
  { id: "mail",     name: "Courrier",   glyph: "mail",     colors: ["#3EC5F2", "#1D8FD6"] },
  { id: "calendar", name: "Calendrier", glyph: "calendar", colors: ["#FF6B6B", "#D83A4F"] },
  { id: "store",    name: "Store",      glyph: "bag",      colors: ["#C084FC", "#7C3AED"] },
  { id: "settings", name: "Paramètres", glyph: "sliders",  colors: ["#8A93A6", "#565E70"] },
  { id: "terminal", name: "Terminal",   glyph: "terminal", colors: ["#3A3F4E", "#1C1F28"] },
  { id: "notes",    name: "Notes",      glyph: "note",     colors: ["#FFD15C", "#F0A62A"] },
  { id: "photos",   name: "Photos",     glyph: "image",    colors: ["#F77FB8", "#D9468F"] },
  { id: "music",    name: "Musique",    glyph: "music",    colors: ["#FF6F8E", "#E03A62"] },
  { id: "help",     name: "Aide",       glyph: "info",     colors: ["#8B9BB4", "#5A6782"] },
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
  nebula: { name: "Nebula", file: "../branding/wallpaper/vinx-nebula.svg" },
  minimal: { name: "Nebula épuré", file: "../branding/wallpaper/vinx-nebula-minimal.svg" },
};
const wallpaperUrl = (key) => new URL((WALLPAPERS[key] || WALLPAPERS.nebula).file, location.href).href;

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
    case "settings": {
      const s = Shell.state;
      return `<div class="settings">
        <section><h4>Apparence</h4>
          <div class="settings-row"><span>Thème</span><div class="seg" data-theme-seg><button data-v="light">Clair</button><button data-v="dark">Sombre</button></div></div>
          <div class="settings-row"><span>Couleur d'accent</span><div class="swatches">${["#A855F7", "#6366F1", "#EC4899", "#F97316", "#16A34A", "#0EA5E9"].map((c) => `<button class="sw" style="background:${c}" data-accent="${c}" aria-label="${c}"></button>`).join("")}</div></div>
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
