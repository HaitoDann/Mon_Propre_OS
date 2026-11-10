import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Espaces de travail (bureaux virtuels de KWin) : un point par bureau, le courant allongé.
// Clic sur un point : changer de bureau. Clic sur le bureau courant : vue d'ensemble.
Item {
    id: ind
    readonly property var backend: Tasks.backend
    readonly property int count: backend ? backend.desktopCount : 0
    readonly property int current: backend ? backend.currentDesktopIndex : 0

    visible: count > 1
    implicitWidth: row.implicitWidth + Theme.space2 * 2
    implicitHeight: 24
    Accessible.role: Accessible.PageTabList
    Accessible.name: qsTr("Bureau %1 sur %2").arg(current + 1).arg(count)

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: hover.hovered ? Theme.surfaceHover : "transparent"
    }
    HoverHandler { id: hover }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Repeater {
            model: ind.count
            Rectangle {
                required property int index
                readonly property bool isCurrent: index === ind.current
                width: isCurrent ? 14 : 6
                height: 6
                radius: 3
                anchors.verticalCenter: parent.verticalCenter
                color: isCurrent ? Theme.text : Theme.textTertiary
                Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }
                MouseArea {
                    anchors { fill: parent; margins: -5 }
                    onClicked: parent.isCurrent ? Session.invokeKWinShortcut("Overview") : ind.backend.activateDesktop(parent.index)
                }
            }
        }
    }
}
