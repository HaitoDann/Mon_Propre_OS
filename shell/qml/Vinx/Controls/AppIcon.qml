import QtQuick
import Vinx.Theme
import Vinx.Controls  // types C++ du module (Icon) — import explicite requis avant Qt 6.5

// Icône d'application : « squircle » dégradé + pictogramme blanc (cf. maquette).
Item {
    id: root
    property string iconName
    property color colorTop: Theme.gradientStart
    property color colorBottom: Theme.gradientEnd
    property real size: Theme.dockIcon

    implicitWidth: size; implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: width * 0.23
        gradient: Gradient {
            GradientStop { position: 0; color: root.colorTop }
            GradientStop { position: 1; color: root.colorBottom }
        }
        // Reflet supérieur discret
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            height: 1; radius: 1
            color: "#40FFFFFF"
        }
    }
    Icon {
        anchors.centerIn: parent
        width: parent.width * 0.54; height: width
        name: root.iconName
        color: "white"
    }
}
