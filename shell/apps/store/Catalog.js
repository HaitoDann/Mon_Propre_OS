.pragma library
// Catalogue du Store (ADR 0027) : rayons et « Sélection VinX ».
// Chaque logiciel : pkg (paquet Debian, prioritaire) et/ou flatpak (identifiant Flathub).
// Le nom et le résumé sont les nôtres (en français, traduits par qsTr, contexte « Catalog ») ; le logo et l'état « installé » viennent
// d'AppStream (Debian) ou de Flatpak. Un logiciel introuvable dans les deux sources n'est pas affiché.
const categories = [
    { id: "office", name: qsTr("Bureautique"), tint: "#2E9BFF", apps: [
        { pkg: "libreoffice-writer", name: "LibreOffice Writer", summary: qsTr("Traitement de texte compatible Word") },
        { pkg: "libreoffice-calc", name: "LibreOffice Calc", summary: qsTr("Tableur compatible Excel") },
        { pkg: "libreoffice-impress", name: "LibreOffice Impress", summary: qsTr("Présentations compatibles PowerPoint") },
        { pkg: "okular", name: "Okular", summary: qsTr("Lire et annoter des PDF") },
        { pkg: "simple-scan", name: qsTr("Numériseur"), summary: qsTr("Numériser des documents") },
        { pkg: "xournalpp", flatpak: "com.github.xournalpp.xournalpp", name: "Xournal++", summary: qsTr("Notes manuscrites et annotation de PDF") },
        { pkg: "calibre", name: "Calibre", summary: qsTr("Bibliothèque de livres numériques") },
        { pkg: "gnucash", name: "GnuCash", summary: qsTr("Comptabilité personnelle") },
        { pkg: "scribus", name: "Scribus", summary: qsTr("Mise en page et publication") },
        { flatpak: "org.onlyoffice.desktopeditors", name: "ONLYOFFICE", summary: qsTr("Suite compatible Microsoft Office") },
        { flatpak: "org.zotero.Zotero", name: "Zotero", summary: qsTr("Gestion de références") },
        { flatpak: "md.obsidian.Obsidian", name: "Obsidian", summary: qsTr("Prise de notes reliées") } ] },
    { id: "internet", name: qsTr("Internet"), tint: "#FF6B57", apps: [
        { pkg: "firefox-esr", name: "Firefox", summary: qsTr("Navigateur web") },
        { pkg: "chromium", name: "Chromium", summary: qsTr("Navigateur web") },
        { pkg: "thunderbird", name: "Thunderbird", summary: qsTr("Courrier électronique et agenda") },
        { pkg: "filezilla", name: "FileZilla", summary: qsTr("Transfert de fichiers (FTP, SFTP)") },
        { pkg: "transmission-qt", name: "Transmission", summary: qsTr("Téléchargements BitTorrent") },
        { pkg: "remmina", name: "Remmina", summary: qsTr("Bureau à distance") },
        { flatpak: "org.signal.Signal", name: "Signal", summary: qsTr("Messagerie chiffrée") },
        { flatpak: "com.discordapp.Discord", name: "Discord", summary: qsTr("Communautés et vocal") },
        { flatpak: "us.zoom.Zoom", name: "Zoom", summary: qsTr("Visioconférence") } ] },
    { id: "graphics", name: qsTr("Graphisme et photo"), tint: "#F0508C", apps: [
        { pkg: "gimp", flatpak: "org.gimp.GIMP", name: "GIMP", summary: qsTr("Retouche photo et création graphique") },
        { pkg: "inkscape", flatpak: "org.inkscape.Inkscape", name: "Inkscape", summary: qsTr("Dessin vectoriel") },
        { pkg: "krita", flatpak: "org.kde.krita", name: "Krita", summary: qsTr("Peinture numérique") },
        { pkg: "darktable", name: "darktable", summary: qsTr("Développement de photos RAW") },
        { pkg: "digikam", name: "digiKam", summary: qsTr("Gérer sa photothèque") },
        { pkg: "shotwell", name: "Shotwell", summary: qsTr("Organiser ses photos") },
        { pkg: "blender", name: "Blender", summary: qsTr("Modélisation et animation 3D") } ] },
    { id: "media", name: qsTr("Audio et vidéo"), tint: "#FFB21E", apps: [
        { pkg: "vlc", name: "VLC", summary: qsTr("Lecteur multimédia qui lit presque tout") },
        { pkg: "audacity", flatpak: "org.audacityteam.Audacity", name: "Audacity", summary: qsTr("Enregistrer et monter du son") },
        { pkg: "kdenlive", flatpak: "org.kde.kdenlive", name: "Kdenlive", summary: qsTr("Montage vidéo") },
        { pkg: "obs-studio", flatpak: "com.obsproject.Studio", name: "OBS Studio", summary: qsTr("Enregistrer l'écran et diffuser") },
        { pkg: "handbrake", name: "HandBrake", summary: qsTr("Convertir des vidéos") },
        { pkg: "elisa", name: "Elisa", summary: qsTr("Lecteur de musique") },
        { flatpak: "com.spotify.Client", name: "Spotify", summary: qsTr("Musique en ligne") } ] },
    { id: "games", name: qsTr("Jeux"), tint: "#10DD8C", apps: [
        { pkg: "supertuxkart", name: "SuperTuxKart", summary: qsTr("Course de karts") },
        { pkg: "0ad", name: "0 A.D.", summary: qsTr("Stratégie historique en temps réel") },
        { pkg: "kpat", name: "KPatience", summary: qsTr("Jeux de cartes et solitaires") },
        { pkg: "kmines", name: "KMines", summary: qsTr("Démineur") },
        { pkg: "lutris", flatpak: "net.lutris.Lutris", name: "Lutris", summary: qsTr("Lanceur de jeux") },
        { flatpak: "com.valvesoftware.Steam", name: "Steam", summary: qsTr("Plateforme de jeux") } ] },
    { id: "education", name: qsTr("Éducation"), tint: "#14C8C8", apps: [
        { pkg: "gcompris-qt", name: "GCompris", summary: qsTr("Activités éducatives pour les enfants") },
        { pkg: "stellarium", name: "Stellarium", summary: qsTr("Planétarium") },
        { pkg: "marble", name: "Marble", summary: qsTr("Globe et cartes") },
        { pkg: "kalzium", name: "Kalzium", summary: qsTr("Tableau périodique des éléments") },
        { pkg: "anki", name: "Anki", summary: qsTr("Cartes mémoire pour apprendre") },
        { pkg: "tuxpaint", name: "Tux Paint", summary: qsTr("Dessin pour les enfants") },
        { pkg: "kgeography", name: "KGeography", summary: qsTr("Apprendre la géographie") } ] },
    { id: "dev", name: qsTr("Développement"), tint: "#9AA09C", apps: [
        { pkg: "geany", name: "Geany", summary: qsTr("Éditeur de code léger") },
        { pkg: "meld", name: "Meld", summary: qsTr("Comparer des fichiers et des dossiers") },
        { pkg: "git-cola", name: "Git Cola", summary: qsTr("Client Git graphique") },
        { flatpak: "com.vscodium.codium", name: "VSCodium", summary: qsTr("Éditeur de code") },
        { flatpak: "io.podman_desktop.PodmanDesktop", name: "Podman Desktop", summary: qsTr("Conteneurs") } ] },
    { id: "system", name: qsTr("Outils système"), tint: "#C2E02E", apps: [
        { pkg: "keepassxc", name: "KeePassXC", summary: qsTr("Coffre-fort de mots de passe") },
        { pkg: "gparted", name: "GParted", summary: qsTr("Gérer les partitions des disques") },
        { pkg: "gnome-disk-utility", name: qsTr("Disques"), summary: qsTr("Disques, clés USB et images") },
        { pkg: "filelight", name: "Filelight", summary: qsTr("Voir ce qui occupe le disque") },
        { pkg: "bleachbit", name: "BleachBit", summary: qsTr("Libérer de l'espace") },
        { pkg: "kleopatra", name: "Kleopatra", summary: qsTr("Chiffrement et signatures") },
        { flatpak: "com.github.tchx84.Flatseal", name: "Flatseal", summary: qsTr("Permissions des applications Flathub") } ] }
];

// Sélection VinX : un logiciel mis en avant à chaque ouverture du Store.
const selection = [
    { pkg: "gimp", tagline: qsTr("Retouchez vos photos comme un pro, librement.") },
    { pkg: "vlc", tagline: qsTr("Toutes vos vidéos et votre musique, sans rien installer d'autre.") },
    { pkg: "inkscape", tagline: qsTr("Logos, affiches et schémas en dessin vectoriel.") },
    { pkg: "keepassxc", tagline: qsTr("Tous vos mots de passe dans un coffre-fort chiffré.") },
    { pkg: "obs-studio", tagline: qsTr("Enregistrez votre écran pour un tutoriel ou une réunion.") },
    { pkg: "stellarium", tagline: qsTr("Le ciel de ce soir, depuis votre bureau.") },
    { pkg: "xournalpp", tagline: qsTr("Annotez vos PDF et prenez des notes à la main.") },
    { pkg: "kdenlive", tagline: qsTr("Montez vos vidéos de vacances en quelques clics.") }
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
