import QtQuick
import Vinx.Theme
import Vinx.Controls  // types C++ du module (Icon) — import explicite requis avant Qt 6.5

// Icône d'application VinX (ADR 0018) : tuile neutre arrondie, pictogramme à l'encre au trait,
// un point de couleur qui identifie l'application. Même dessin que le thème d'icônes « VinX ».
Item {
    id: root
    property string iconName
    property color tint: "#8A8983"     // couleur du point
    property real size: Theme.dockIcon

    implicitWidth: size; implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: width * 0.24
        color: Theme.dark ? "#2A2D2B" : "#E3E1DB"
        border.width: 1
        border.color: Theme.border
    }
    Icon {
        anchors.centerIn: parent
        width: parent.width * 0.5; height: width
        name: root.iconName
        color: Theme.text
    }
    Rectangle {
        width: root.width * 0.15; height: width; radius: width / 2
        x: root.width * 0.80 - width / 2; y: root.height * 0.20 - height / 2
        color: root.tint
        border.width: Theme.dark && Qt.colorEqual(root.tint, "#141414") ? 1 : 0
        border.color: Theme.text
    }
}
