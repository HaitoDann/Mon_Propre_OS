import QtQuick
import Vinx.Theme

// Interrupteur marche/arrêt.
Item {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    function toggle() { checked = !checked; toggled(checked) }

    implicitWidth: 38; implicitHeight: 22
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.45
    Keys.onSpacePressed: toggle()
    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: checked

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.surfaceActive
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.text
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        Rectangle {
            id: knob
            width: parent.height - 4; height: width; radius: width / 2
            y: 2
            x: root.checked ? parent.width - width - 2 : 2
            color: "white"
            Behavior on x { NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.toggle()
    }
}
