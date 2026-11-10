import QtQuick
import Vinx.Theme

// Surface du dock (layer-shell, ancrée en bas au centre). La hauteur laisse la place
// à l'agrandissement et à l'infobulle ; seule la zone du plateau est réservée.
Window {
    id: win
    readonly property alias reservedHeight: dock.reservedHeight
    width: Math.min(Screen.width, Math.max(400, dock.childrenRect.width + Theme.dockIconMax * 2))
    height: dock.reservedHeight + (Theme.dockIconMax - Theme.dockIcon) + 40
    color: "transparent"
    visible: false
    title: "vinx-dock"
    Dock {
        id: dock
        anchors.fill: parent
        screenOffset: Qt.point((Screen.width - win.width) / 2, Screen.height - win.height)
    }
}
