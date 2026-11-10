import QtQuick
import Vinx.Theme
import Vinx.Controls  // types C++ du module (Icon) — import explicite requis avant Qt 6.5

// Tuile du centre de contrôle : pastille d'icône + titre + état.
Item {
    id: root
    property string iconName
    property string title
    property string subtitle
    property bool checked: false
    signal clicked()

    implicitWidth: 156; implicitHeight: 48
    activeFocusOnTab: true
    Keys.onSpacePressed: clicked()
    Accessible.role: Accessible.CheckBox
    Accessible.name: title
    Accessible.checked: checked

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: mouse.containsMouse ? Theme.surfaceActive : Theme.surfaceHover
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }
    Row {
        anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter }
        spacing: Theme.space2
        Rectangle {
            width: 30; height: 30; radius: 15
            color: root.checked ? Theme.accent : Theme.surfaceActive
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
            Icon {
                anchors.centerIn: parent
                width: 16; height: 16
                name: root.iconName
                color: root.checked ? Theme.accentText : Theme.text
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Label { text: root.title; font.weight: Font.DemiBold }
            Label { text: root.subtitle; level: Label.Secondary; font.pixelSize: Theme.fsXs }
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: { root.forceActiveFocus(); root.clicked() }
    }
}
