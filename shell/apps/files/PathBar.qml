import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.Files

// Fil d'Ariane cliquable ; Ctrl+L ou clic sur la zone vide : saisie d'un chemin.
Item {
    id: root
    property FolderModel model
    property bool editing: false
    signal openRequested(url url)
    height: 30

    function edit() { editing = true; input.text = model.url.toString().startsWith("file://") ? decodeURIComponent(model.url.toString().slice(7)) : model.url.toString(); input.selectAll(); input.forceActiveFocus() }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: root.editing ? Theme.surfaceSunken : "transparent"
        border.width: root.editing ? 2 : 0
        border.color: Theme.accentForeground
    }
    MouseArea { anchors.fill: parent; enabled: !root.editing; onClicked: root.edit() }

    Row {
        id: crumbs
        visible: !root.editing
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        spacing: 0
        clip: true
        width: Math.min(implicitWidth, root.width)
        Repeater {
            model: root.editing ? [] : (root.model.url, root.model.breadcrumb())
            Row {
                id: crumb
                required property var modelData
                required property int index
                readonly property bool last: index === root.model.breadcrumb().length - 1
                spacing: 0
                Icon { visible: crumb.index > 0; name: "chevron-r"; width: 14; height: 14; color: Theme.textTertiary; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    width: lbl.implicitWidth + Theme.space2 * 2; height: 26
                    radius: Theme.radiusSm
                    color: ma.containsMouse && !crumb.last ? Theme.surfaceHover : "transparent"
                    Label { id: lbl; anchors.centerIn: parent; text: crumb.modelData.name; font.weight: crumb.last ? Font.DemiBold : Font.Normal; level: crumb.last ? Label.Primary : Label.Secondary }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: root.openRequested(crumb.modelData.url) }
                }
            }
        }
    }
    TextInput {
        id: input
        visible: root.editing
        anchors { fill: parent; leftMargin: Theme.space3; rightMargin: Theme.space3 }
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text; font.pixelSize: Theme.fsMd; clip: true
        selectByMouse: true
        Accessible.name: qsTr("Chemin")
        onAccepted: { root.editing = false; root.openRequested(root.model.urlFromText(text)) }
        Keys.onEscapePressed: root.editing = false
        onActiveFocusChanged: if (!activeFocus) root.editing = false
    }
}
