import QtQuick
import Vinx.Theme
import Vinx.Controls

// Ligne de réglage : libellé (et description) à gauche, contrôle à droite.
Item {
    id: row
    property string title
    property string description
    default property alias control: slot.data
    width: parent ? parent.width : 400
    height: Math.max(48, texts.implicitHeight + Theme.space3 * 2)

    Column {
        id: texts
        anchors { left: parent.left; verticalCenter: parent.verticalCenter; right: slot.left; rightMargin: Theme.space4 }
        Label { text: row.title; width: parent.width }
        Label { visible: row.description !== ""; text: row.description; level: Label.Secondary; font.pixelSize: Theme.fsSm; width: parent.width; wrapMode: Text.WordWrap }
    }
    Item {
        id: slot
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: childrenRect.width; height: childrenRect.height
    }
    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Theme.border }
}
