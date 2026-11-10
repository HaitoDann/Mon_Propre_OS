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
    ListView {
        visible: Notifications.count > 0
        width: parent.width
        height: Math.min(contentHeight, 260)
        clip: true
        spacing: Theme.space2
        model: Notifications
        delegate: Rectangle {
            required property int id
            required property string summary
            required property string body
            required property string appName
            required property date time
            width: ListView.view.width
            height: col.implicitHeight + Theme.space2 * 2
            radius: Theme.radiusMd
            color: Theme.surfaceHover
            Column {
                id: col
                x: Theme.space3; y: Theme.space2
                width: parent.width - Theme.space3 * 2 - 24
                spacing: 2
                Label { text: appName + " · " + Qt.formatTime(time, "HH:mm"); level: Label.Tertiary; font.pixelSize: Theme.fsXs; width: parent.width }
                Label { text: summary; font.weight: Font.DemiBold; width: parent.width }
                Label { visible: body !== ""; text: body; level: Label.Secondary; font.pixelSize: Theme.fsSm; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
            }
            IconButton {
                anchors { right: parent.right; top: parent.top; margins: 4 }
                width: 22; height: 22
                flat: true
                iconName: "close"
                toolTip: qsTr("Effacer")
                onClicked: Notifications.dismiss(id)
            }
        }
    }
}
