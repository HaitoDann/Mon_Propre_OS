import QtQuick
import Vinx.Theme
import Vinx.Controls

// Zone cliquable de la barre supérieure, surlignée quand son panneau est ouvert.
Item {
    id: root
    property string panel
    property alias spacing: row.spacing
    default property alias content: row.data
    readonly property bool active: ShellState.openPanel === panel
    signal activated()

    implicitWidth: row.implicitWidth + Theme.space2 * 2
    implicitHeight: 24
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Keys.onSpacePressed: open()
    Keys.onReturnPressed: open()

    function open() {
        const p = mapToItem(null, 0, 0)
        const scr = Window.window && Window.window.screen ? Window.window.screen.name : ""
        ShellState.toggle(panel, Qt.rect(p.x, p.y, width, height + (Theme.topbarHeight - height) / 2), scr)
        activated()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: root.active ? Theme.surfaceActive : mouse.containsMouse ? Theme.surfaceHover : "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accentForeground
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.space2
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.open()
    }
}
