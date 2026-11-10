import QtQuick
import Vinx.Theme

// Fenêtre de la barre (surface layer-shell ancrée en haut, configurée par vinx-shell).
Window {
    width: Screen.width
    height: Theme.topbarHeight
    color: "transparent"
    visible: false   // affichée par le C++ après configuration layer-shell
    title: "vinx-topbar"
    AppearanceSync {}
    TopBar { anchors.fill: parent }
}
