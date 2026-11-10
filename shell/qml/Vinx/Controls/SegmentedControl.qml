import QtQuick
import Vinx.Theme

// Choix exclusif entre quelques options (ex. thème Clair / Sombre).
Item {
    id: root
    property var model: []
    property int currentIndex: 0
    signal activated(int index)

    implicitHeight: 28
    implicitWidth: row.implicitWidth + 4
    activeFocusOnTab: true
    Keys.onLeftPressed: select(currentIndex - 1)
    Keys.onRightPressed: select(currentIndex + 1)

    function select(i) {
        if (i < 0 || i >= model.length || i === currentIndex) return
        currentIndex = i
        activated(i)
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: Theme.surfaceHover
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accent
    }
    Row {
        id: row
        anchors { fill: parent; margins: 2 }
        Repeater {
            id: rep
            model: root.model
            Item {
                width: label.implicitWidth + Theme.space3 * 2
                height: row.height
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusXs
                    color: index === root.currentIndex ? Theme.surfaceWindow : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                }
                Label {
                    id: label
                    anchors.centerIn: parent
                    text: modelData
                    font.pixelSize: Theme.fsSm
                    font.weight: index === root.currentIndex ? Font.DemiBold : Font.Normal
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { root.forceActiveFocus(); root.select(index) }
                }
            }
        }
    }
}
