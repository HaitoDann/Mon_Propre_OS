.pragma library
// Catalogue du Store : packs thématiques d'applications Flathub.
// Les identifiants sont ceux de Flathub (https://flathub.org).
const packs = [
    { id: "dev", name: "Développement", glyph: "terminal", tint: "#2E3036",
      summary: "Éditeur de code, gestion de versions et conteneurs.",
      apps: [ { id: "com.vscodium.codium", name: "VSCodium", summary: "Éditeur de code" },
              { id: "io.github.shiftey.Desktop", name: "GitHub Desktop", summary: "Client Git graphique" },
              { id: "io.podman_desktop.PodmanDesktop", name: "Podman Desktop", summary: "Conteneurs" } ] },
    { id: "office", name: "Bureautique+", glyph: "doc", tint: "#4F60A3",
      summary: "Compléments à LibreOffice : documents, notes manuscrites, bibliographie.",
      apps: [ { id: "org.onlyoffice.desktopeditors", name: "ONLYOFFICE", summary: "Suite compatible Microsoft Office" },
              { id: "com.github.xournalpp.xournalpp", name: "Xournal++", summary: "Annotation de PDF et prise de notes" },
              { id: "org.zotero.Zotero", name: "Zotero", summary: "Gestion de références" } ] },
    { id: "media", name: "Multimédia", glyph: "music", tint: "#A34E62",
      summary: "Montage vidéo, enregistrement d'écran et musique.",
      apps: [ { id: "org.kde.kdenlive", name: "Kdenlive", summary: "Montage vidéo" },
              { id: "com.obsproject.Studio", name: "OBS Studio", summary: "Enregistrement et diffusion" },
              { id: "org.audacityteam.Audacity", name: "Audacity", summary: "Édition audio" } ] },
    { id: "graphics", name: "Graphisme", glyph: "image", tint: "#B8693F",
      summary: "Retouche photo, illustration vectorielle et peinture numérique.",
      apps: [ { id: "org.gimp.GIMP", name: "GIMP", summary: "Retouche d'images" },
              { id: "org.inkscape.Inkscape", name: "Inkscape", summary: "Dessin vectoriel" },
              { id: "org.kde.krita", name: "Krita", summary: "Peinture numérique" } ] },
    { id: "games", name: "Jeux", glyph: "grid", tint: "#3E8460",
      summary: "Plateformes de jeux et lanceurs.",
      apps: [ { id: "com.valvesoftware.Steam", name: "Steam", summary: "Plateforme de jeux" },
              { id: "net.lutris.Lutris", name: "Lutris", summary: "Gestionnaire de jeux" },
              { id: "com.heroicgameslauncher.hgl", name: "Heroic", summary: "Epic Games et GOG" } ] },
    { id: "chat", name: "Communication", glyph: "mail", tint: "#3F7896",
      summary: "Messageries et visioconférence.",
      apps: [ { id: "org.signal.Signal", name: "Signal", summary: "Messagerie chiffrée" },
              { id: "org.telegram.desktop", name: "Telegram", summary: "Messagerie" },
              { id: "com.discordapp.Discord", name: "Discord", summary: "Communautés et vocal" } ] }
];

function ids(pack) { return pack.apps.map(a => a.id) }
