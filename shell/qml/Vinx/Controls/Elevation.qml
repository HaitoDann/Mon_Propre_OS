import QtQuick
import Vinx.Theme

// Ombre portée légère, sans effet graphique (anneaux concentriques translucides).
// Placée sous un élément arrondi : Elevation { anchors.fill: parent; radius: parent.radius; level: 2 }
Item {
    id: root
    property real radius: 0
    property int level: 1          // 0 = aucune, 1 = légère, 2 = marquée
    z: -1

    Repeater {
        model: root.level > 0 ? 4 * root.level : 0
        Rectangle {
            readonly property real spread: (index + 1) * 2
            x: -spread; y: -spread + root.level * 3
            width: root.width + spread * 2; height: root.height + spread * 2
            radius: root.radius + spread
            color: "transparent"
            border.width: 2
            border.color: Theme.shadow
            opacity: 0.12 * (1 - index / (4 * root.level))
        }
    }
}
