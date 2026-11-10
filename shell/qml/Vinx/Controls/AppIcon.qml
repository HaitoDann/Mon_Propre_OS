import QtQuick
import Vinx.Theme
import Vinx.Controls  // types C++ du module (Icon) — import explicite requis avant Qt 6.5

// Icône d'application : carré arrondi d'une teinte unie et sobre + pictogramme blanc.
// Un très léger éclaircissement vers le haut donne du volume sans effet de dégradé marqué.
Item {
    id: root
    property string iconName
    property color tint: "#6B6E76"
    property real size: Theme.dockIcon

    implicitWidth: size; implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: width * 0.23
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(root.tint, 1.06) }
            GradientStop { position: 1; color: root.tint }
        }
        border.width: 1
        border.color: "#14FFFFFF"
    }
    Icon {
        anchors.centerIn: parent
        width: parent.width * 0.5; height: width
        name: root.iconName
        color: "white"
    }
}
