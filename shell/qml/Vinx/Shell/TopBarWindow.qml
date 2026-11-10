import QtQuick
import Vinx.Theme
import Vinx.System

// Fenêtre de la barre (surface layer-shell ancrée en haut, configurée par vinx-shell).
Window {
    width: Screen.width
    height: Theme.topbarHeight
    color: "transparent"
    visible: false   // affichée par le C++ après configuration layer-shell
    title: "vinx-topbar"
    AppearanceSync {}
    // Les fenêtres des applications suivent l'apparence (palette KDE VinX claire / sombre).
    Connections {
        target: Theme
        function onDarkChanged() { Session.launch("plasma-apply-colorscheme", [Theme.dark ? "VinXDark" : "VinXLight"]) }
    }
    TopBar { anchors.fill: parent }
}
