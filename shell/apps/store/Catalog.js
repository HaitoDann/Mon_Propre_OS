.pragma library
// Catalogue du Store (ADR 0027) : rayons et « Sélection VinX ».
// Chaque logiciel : pkg (paquet Debian, prioritaire) et/ou flatpak (identifiant Flathub).
// Le nom et le résumé sont les nôtres (en français) ; le logo et l'état « installé » viennent
// d'AppStream (Debian) ou de Flatpak. Un logiciel introuvable dans les deux sources n'est pas affiché.
const categories = [
    { id: "office", name: "Bureautique", tint: "#2E9BFF", apps: [
        { pkg: "libreoffice-writer", name: "LibreOffice Writer", summary: "Traitement de texte compatible Word" },
        { pkg: "libreoffice-calc", name: "LibreOffice Calc", summary: "Tableur compatible Excel" },
        { pkg: "libreoffice-impress", name: "LibreOffice Impress", summary: "Présentations compatibles PowerPoint" },
        { pkg: "okular", name: "Okular", summary: "Lire et annoter des PDF" },
        { pkg: "simple-scan", name: "Numériseur", summary: "Numériser des documents" },
        { pkg: "xournalpp", flatpak: "com.github.xournalpp.xournalpp", name: "Xournal++", summary: "Notes manuscrites et annotation de PDF" },
        { pkg: "calibre", name: "Calibre", summary: "Bibliothèque de livres numériques" },
        { pkg: "gnucash", name: "GnuCash", summary: "Comptabilité personnelle" },
        { pkg: "scribus", name: "Scribus", summary: "Mise en page et publication" },
        { flatpak: "org.onlyoffice.desktopeditors", name: "ONLYOFFICE", summary: "Suite compatible Microsoft Office" },
        { flatpak: "org.zotero.Zotero", name: "Zotero", summary: "Gestion de références" },
        { flatpak: "md.obsidian.Obsidian", name: "Obsidian", summary: "Prise de notes reliées" } ] },
    { id: "internet", name: "Internet", tint: "#FF6B57", apps: [
        { pkg: "firefox-esr", name: "Firefox", summary: "Navigateur web" },
        { pkg: "chromium", name: "Chromium", summary: "Navigateur web" },
        { pkg: "thunderbird", name: "Thunderbird", summary: "Courrier électronique et agenda" },
        { pkg: "filezilla", name: "FileZilla", summary: "Transfert de fichiers (FTP, SFTP)" },
        { pkg: "transmission-qt", name: "Transmission", summary: "Téléchargements BitTorrent" },
        { pkg: "remmina", name: "Remmina", summary: "Bureau à distance" },
        { flatpak: "org.signal.Signal", name: "Signal", summary: "Messagerie chiffrée" },
        { flatpak: "com.discordapp.Discord", name: "Discord", summary: "Communautés et vocal" },
        { flatpak: "us.zoom.Zoom", name: "Zoom", summary: "Visioconférence" } ] },
    { id: "graphics", name: "Graphisme et photo", tint: "#F0508C", apps: [
        { pkg: "gimp", flatpak: "org.gimp.GIMP", name: "GIMP", summary: "Retouche photo et création graphique" },
        { pkg: "inkscape", flatpak: "org.inkscape.Inkscape", name: "Inkscape", summary: "Dessin vectoriel" },
        { pkg: "krita", flatpak: "org.kde.krita", name: "Krita", summary: "Peinture numérique" },
        { pkg: "darktable", name: "darktable", summary: "Développement de photos RAW" },
        { pkg: "digikam", name: "digiKam", summary: "Gérer sa photothèque" },
        { pkg: "shotwell", name: "Shotwell", summary: "Organiser ses photos" },
        { pkg: "blender", name: "Blender", summary: "Modélisation et animation 3D" } ] },
    { id: "media", name: "Audio et vidéo", tint: "#FFB21E", apps: [
        { pkg: "vlc", name: "VLC", summary: "Lecteur multimédia qui lit presque tout" },
        { pkg: "audacity", flatpak: "org.audacityteam.Audacity", name: "Audacity", summary: "Enregistrer et monter du son" },
        { pkg: "kdenlive", flatpak: "org.kde.kdenlive", name: "Kdenlive", summary: "Montage vidéo" },
        { pkg: "obs-studio", flatpak: "com.obsproject.Studio", name: "OBS Studio", summary: "Enregistrer l'écran et diffuser" },
        { pkg: "handbrake", name: "HandBrake", summary: "Convertir des vidéos" },
        { pkg: "elisa", name: "Elisa", summary: "Lecteur de musique" },
        { flatpak: "com.spotify.Client", name: "Spotify", summary: "Musique en ligne" } ] },
    { id: "games", name: "Jeux", tint: "#10DD8C", apps: [
        { pkg: "supertuxkart", name: "SuperTuxKart", summary: "Course de karts" },
        { pkg: "0ad", name: "0 A.D.", summary: "Stratégie historique en temps réel" },
        { pkg: "kpat", name: "KPatience", summary: "Jeux de cartes et solitaires" },
        { pkg: "kmines", name: "KMines", summary: "Démineur" },
        { pkg: "lutris", flatpak: "net.lutris.Lutris", name: "Lutris", summary: "Lanceur de jeux" },
        { flatpak: "com.valvesoftware.Steam", name: "Steam", summary: "Plateforme de jeux" } ] },
    { id: "education", name: "Éducation", tint: "#14C8C8", apps: [
        { pkg: "gcompris-qt", name: "GCompris", summary: "Activités éducatives pour les enfants" },
        { pkg: "stellarium", name: "Stellarium", summary: "Planétarium" },
        { pkg: "marble", name: "Marble", summary: "Globe et cartes" },
        { pkg: "kalzium", name: "Kalzium", summary: "Tableau périodique des éléments" },
        { pkg: "anki", name: "Anki", summary: "Cartes mémoire pour apprendre" },
        { pkg: "tuxpaint", name: "Tux Paint", summary: "Dessin pour les enfants" },
        { pkg: "kgeography", name: "KGeography", summary: "Apprendre la géographie" } ] },
    { id: "dev", name: "Développement", tint: "#9AA09C", apps: [
        { pkg: "geany", name: "Geany", summary: "Éditeur de code léger" },
        { pkg: "meld", name: "Meld", summary: "Comparer des fichiers et des dossiers" },
        { pkg: "git-cola", name: "Git Cola", summary: "Client Git graphique" },
        { flatpak: "com.vscodium.codium", name: "VSCodium", summary: "Éditeur de code" },
        { flatpak: "io.podman_desktop.PodmanDesktop", name: "Podman Desktop", summary: "Conteneurs" } ] },
    { id: "system", name: "Outils système", tint: "#C2E02E", apps: [
        { pkg: "keepassxc", name: "KeePassXC", summary: "Coffre-fort de mots de passe" },
        { pkg: "gparted", name: "GParted", summary: "Gérer les partitions des disques" },
        { pkg: "gnome-disk-utility", name: "Disques", summary: "Disques, clés USB et images" },
        { pkg: "filelight", name: "Filelight", summary: "Voir ce qui occupe le disque" },
        { pkg: "bleachbit", name: "BleachBit", summary: "Libérer de l'espace" },
        { pkg: "kleopatra", name: "Kleopatra", summary: "Chiffrement et signatures" },
        { flatpak: "com.github.tchx84.Flatseal", name: "Flatseal", summary: "Permissions des applications Flathub" } ] }
];

// Sélection VinX : un logiciel mis en avant à chaque ouverture du Store.
const selection = [
    { pkg: "gimp", tagline: "Retouchez vos photos comme un pro, librement." },
    { pkg: "vlc", tagline: "Toutes vos vidéos et votre musique, sans rien installer d'autre." },
    { pkg: "inkscape", tagline: "Logos, affiches et schémas en dessin vectoriel." },
    { pkg: "keepassxc", tagline: "Tous vos mots de passe dans un coffre-fort chiffré." },
    { pkg: "obs-studio", tagline: "Enregistrez votre écran pour un tutoriel ou une réunion." },
    { pkg: "stellarium", tagline: "Le ciel de ce soir, depuis votre bureau." },
    { pkg: "xournalpp", tagline: "Annotez vos PDF et prenez des notes à la main." },
    { pkg: "kdenlive", tagline: "Montez vos vidéos de vacances en quelques clics." }
];

// Les plus demandés, en tête de la une.
const popular = ["firefox-esr", "vlc", "gimp", "libreoffice-writer", "thunderbird", "inkscape", "com.spotify.Client", "obs-studio"];

function all() {
    const out = [];
    for (const c of categories)
        for (const a of c.apps)
            out.push(Object.assign({ category: c.id, tint: c.tint }, a));
    return out;
}
function find(key) { return all().find(a => a.pkg === key || a.flatpak === key) || null }
function packages() { return all().filter(a => a.pkg).map(a => a.pkg) }
function category(id) { return categories.find(c => c.id === id) || null }
