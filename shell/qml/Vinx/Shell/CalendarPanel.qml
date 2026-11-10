import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Calendrier du mois (navigation par mois) et zone de notifications (étape 6).
Column {
    id: cal
    property int offset: 0
    readonly property date today: new Date()
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    spacing: Theme.space3
    width: 300

    function reset() { offset = 0 }

    Item {
        width: parent.width; height: 28
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                const s = cal.shown.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                return s.charAt(0).toUpperCase() + s.slice(1)
            }
            font.weight: Font.DemiBold
            font.pixelSize: Theme.fsLg
        }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 4
            IconButton { iconName: "chevron-l"; flat: true; toolTip: qsTr("Mois précédent"); onClicked: cal.offset-- }
            Button { text: qsTr("Aujourd'hui"); variant: Button.Ghost; visible: cal.offset !== 0; onClicked: cal.offset = 0 }
            IconButton { iconName: "chevron-r"; flat: true; toolTip: qsTr("Mois suivant"); onClicked: cal.offset++ }
        }
    }

    Grid {
        id: grid
        columns: 7
        readonly property real cell: cal.width / 7
        readonly property int firstDay: (cal.shown.getDay() + 6) % 7          // lundi = 0
        readonly property int daysInMonth: new Date(cal.shown.getFullYear(), cal.shown.getMonth() + 1, 0).getDate()
        readonly property int daysPrev: new Date(cal.shown.getFullYear(), cal.shown.getMonth(), 0).getDate()

        Repeater {
            model: [qsTr("L"), qsTr("M"), qsTr("M"), qsTr("J"), qsTr("V"), qsTr("S"), qsTr("D")]
            Label {
                width: grid.cell; height: 24
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                level: Label.Tertiary
                font.pixelSize: Theme.fsXs
                font.weight: Font.DemiBold
            }
        }
        Repeater {
            model: 42
            Item {
                readonly property int n: index - grid.firstDay + 1
                readonly property bool inMonth: n >= 1 && n <= grid.daysInMonth
                readonly property bool isToday: inMonth && cal.offset === 0 && n === cal.today.getDate()
                width: grid.cell; height: 32
                Rectangle {
                    anchors.centerIn: parent
                    width: 28; height: 28; radius: 14
                    color: parent.isToday ? Theme.accent : "transparent"
                }
                Label {
                    anchors.centerIn: parent
                    text: parent.n < 1 ? grid.daysPrev + parent.n : parent.n > grid.daysInMonth ? parent.n - grid.daysInMonth : parent.n
                    color: parent.isToday ? Theme.accentText : parent.inMonth ? Theme.text : Theme.textTertiary
                    font.pixelSize: Theme.fsSm
                    font.weight: parent.isToday ? Font.DemiBold : Font.Normal
                }
            }
        }
    }

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
