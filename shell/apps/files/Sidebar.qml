import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.Files

// Barre latérale : emplacements, puis appareils (disques, clés USB, réseau).
Rectangle {
    id: root
    property url currentUrl
    property FolderModel source
    signal openRequested(url url)

    width: 210
    color: Theme.surfaceSunken
    property var places: source ? source.places() : []
    // Rafraîchit la liste des disques (branchement d'une clé USB).
    Timer { interval: 4000; running: true; repeat: true; onTriggered: { const p = root.source.places(); if (JSON.stringify(p) !== JSON.stringify(root.places)) root.places = p } }

    Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.border }

    ListView {
        anchors { fill: parent; margins: Theme.space2; topMargin: Theme.space4 }
        model: root.places
        spacing: 1
        boundsBehavior: Flickable.StopAtBounds
        section.property: "section"
        section.delegate: Label {
            required property string section
            text: section.toUpperCase()
            level: Label.Tertiary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.6
            height: 30; leftPadding: Theme.space2; verticalAlignment: Text.AlignVCenter
        }
        delegate: Rectangle {
            id: place
            required property var modelData
            readonly property bool active: modelData.url.toString() === root.currentUrl.toString()
            width: ListView.view.width; height: 30
            radius: Theme.radiusSm
            color: active ? Theme.surfaceActive : mouse.containsMouse ? Theme.surfaceHover : "transparent"
            Accessible.role: Accessible.Button
            Accessible.name: modelData.name
            Row {
                anchors { left: parent.left; leftMargin: Theme.space2; right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Theme.space2
                Icon { name: place.modelData.icon; width: 16; height: 16; color: place.active ? Theme.accentForeground : Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                Label { text: place.modelData.name; font.weight: place.active ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; width: parent.width - 30 }
            }
            MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.openRequested(place.modelData.url) }
        }
    }
}
