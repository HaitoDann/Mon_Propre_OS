import QtQuick
import Vinx.Theme

// Surface du dock (layer-shell, ancrée en bas au centre). La hauteur laisse la place
// à l'agrandissement et à l'infobulle ; seule la zone du plateau est réservée.
Window {
    id: win
    readonly property alias reservedHeight: dock.reservedHeight
    // Largeur FIXE (taille normale des icônes + marge d'agrandissement) : la surface ne doit jamais
    // se redimensionner au survol, sinon elle se recentre sous le pointeur (sélection décalée, boucle).
    readonly property int itemCount: dock.backend && dock.backend.model ? dock.backend.model.count : 8
    width: Math.min(Screen.width, (itemCount + 1) * (dock.iconSize + Theme.space2) + dock.iconSize * 2 + Theme.space6 * 2)
    height: dock.reservedHeight + dock.iconSize * 0.33 + 40
    color: "transparent"
    visible: false
    title: "vinx-dock"
    Dock {
        id: dock
        anchors.fill: parent
        screenOffset: Qt.point((Screen.width - win.width) / 2, Screen.height - win.height)
    }
}
