import QtQuick
import Vinx.Theme
import Vinx.Controls

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
    Label { text: qsTr("Aucune notification"); level: Label.Tertiary; font.pixelSize: Theme.fsSm; width: parent.width; horizontalAlignment: Text.AlignHCenter; height: 28 }
}
