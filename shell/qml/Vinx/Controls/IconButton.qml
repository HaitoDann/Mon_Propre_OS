import QtQuick
import Vinx.Theme
import Vinx.Controls  // types C++ du module (Icon) — import explicite requis avant Qt 6.5

// Bouton rond contenant une icône (barres, panneaux).
Item {
    id: root
    property string iconName
    property bool flat: false        // true : fond seulement au survol (barre supérieure)
    property bool highlighted: false // état « ouvert » (menu associé affiché)
    property string toolTip
    signal clicked()

    implicitWidth: 28; implicitHeight: 28
    activeFocusOnTab: true
    Keys.onSpacePressed: clicked()
    Keys.onReturnPressed: clicked()
    Accessible.role: Accessible.Button
    Accessible.name: toolTip || iconName

    Rectangle {
        anchors.fill: parent
        radius: root.flat ? Theme.radiusSm : width / 2
        color: root.highlighted || mouse.pressed ? Theme.surfaceActive
             : mouse.containsMouse ? Theme.surfaceHover
             : root.flat ? "transparent" : Theme.surfaceHover
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accentForeground
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }
    Icon {
        anchors.centerIn: parent
        width: 16; height: 16
        name: root.iconName
        color: Theme.text
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
