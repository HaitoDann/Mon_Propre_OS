import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Calendrier du mois (navigation par mois) et zone de notifications (étape 6).
Column {
    id: cal
    spacing: Theme.space3
    width: 300

    function reset() { grid.offset = 0 }

    CalendarGrid { id: grid; width: parent.width }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    // ---------- Notifications ----------
    Item {
        width: parent.width; height: 24
        Label { text: qsTr("Notifications"); level: Label.Secondary; font.pixelSize: Theme.fsSm; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        Button {
            visible: Notifications.count > 0
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: qsTr("Tout effacer"); variant: Button.Ghost
            onClicked: Notifications.clear()
        }
    }
    Label {
        visible: Notifications.count === 0
        text: Notifications.doNotDisturb ? qsTr("Aucune notification · Ne pas déranger activé") : qsTr("Aucune notification")
        level: Label.Tertiary; font.pixelSize: Theme.fsSm
        width: parent.width; horizontalAlignment: Text.AlignHCenter; height: 28
    }
    // Historique regroupé par application (groupes du plus récent au plus ancien).
    Flickable {
        visible: Notifications.count > 0
        width: parent.width
        height: Math.min(groupsColumn.height, 300)
        contentHeight: groupsColumn.height
        clip: true
        Column {
            id: groupsColumn
            width: parent.width
            spacing: Theme.space3
            Repeater {
                model: { Notifications.revision; return Notifications.groups() }
                Column {
                    id: group
                    required property var modelData
                    width: groupsColumn.width
                    spacing: Theme.space1
                    Item {
                        width: parent.width; height: 22
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: group.modelData.count > 1 ? qsTr("%1 · %2").arg(group.modelData.appName).arg(group.modelData.count) : group.modelData.appName
                            level: Label.Secondary
                            font.pixelSize: Theme.fsSm
                            font.weight: Font.DemiBold
                        }
                        IconButton {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width: 22; height: 22; flat: true
                            iconName: "close"
                            toolTip: qsTr("Effacer les notifications de %1").arg(group.modelData.appName)
                            onClicked: Notifications.dismissApp(group.modelData.appName)
                        }
                    }
                    Repeater {
                        model: group.modelData.items
                        Rectangle {
                            id: card
                            required property var modelData
                            width: group.width
                            height: col.implicitHeight + Theme.space2 * 2
                            radius: Theme.radiusMd
                            color: cardMouse.containsMouse ? Theme.surfaceActive : Theme.surfaceHover
                            border.width: modelData.urgency === 2 ? 1 : 0
                            border.color: Theme.danger
                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: { ShellState.close(); Notifications.activate(card.modelData.id) }
                            }
                            Column {
                                id: col
                                x: Theme.space3; y: Theme.space2
                                width: parent.width - Theme.space3 * 2 - 24
                                spacing: 2
                                Label { text: Qt.formatTime(card.modelData.time, "HH:mm"); level: Label.Tertiary; font.pixelSize: Theme.fsXs; width: parent.width }
                                Label { text: card.modelData.summary; font.weight: Font.DemiBold; width: parent.width }
                                Label { visible: card.modelData.body !== ""; text: card.modelData.body; level: Label.Secondary; font.pixelSize: Theme.fsSm; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
                                Row {
                                    visible: card.modelData.actions.length > 0
                                    spacing: Theme.space2
                                    topPadding: Theme.space1
                                    Repeater {
                                        model: card.modelData.actions
                                        Button {
                                            required property var modelData
                                            text: modelData.label
                                            onClicked: { ShellState.close(); Notifications.invokeAction(card.modelData.id, modelData.key) }
                                        }
                                    }
                                }
                            }
                            IconButton {
                                anchors { right: parent.right; top: parent.top; margins: 4 }
                                width: 22; height: 22
                                flat: true
                                iconName: "close"
                                toolTip: qsTr("Effacer")
                                onClicked: Notifications.dismiss(card.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
