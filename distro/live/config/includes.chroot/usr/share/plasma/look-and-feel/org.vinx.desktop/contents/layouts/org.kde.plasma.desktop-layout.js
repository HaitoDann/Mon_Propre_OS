// Disposition par défaut de VinX OS (API de script Plasma 6).
// Reprend la structure de la maquette : barre supérieure + dock centré.

// ---------- Barre supérieure ----------
var topBar = new Panel;
topBar.location = "top";
topBar.height = Math.round(gridUnit * 1.8);

var launcher = topBar.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "vinx-logo");

topBar.addWidget("org.kde.plasma.appmenu");
topBar.addWidget("org.kde.plasma.panelspacer");
topBar.addWidget("org.kde.plasma.pager");
topBar.addWidget("org.kde.plasma.systemtray");
topBar.addWidget("org.kde.plasma.digitalclock");

// ---------- Dock ----------
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.4);
dock.alignment = "center";
dock.lengthMode = "fit";
dock.floating = true;

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:firefox-esr.desktop",
    "applications:libreoffice-writer.desktop",
    "applications:libreoffice-calc.desktop",
    "applications:thunderbird.desktop",
    "applications:org.kde.discover.desktop",
    "applications:systemsettings.desktop"
]);

// ---------- Fond d'écran ----------
var all = desktops();
for (var i = 0; i < all.length; i++) {
    all[i].wallpaperPlugin = "org.kde.image";
    all[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    all[i].writeConfig("Image", "file:///usr/share/wallpapers/VinX-Graphite/");
}
