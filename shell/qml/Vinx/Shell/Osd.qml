import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Bulle de retour des touches du clavier (volume, luminosité, micro, disposition…) : pilule en bas
// au centre, au-dessus du dock, qui s'efface après 1,5 s (ADR 0028).
Item {
    id: osd
    width: 300
    height: 52
    property string kind: ""
    property string icon: "volume"
    property int percent: -1
    property string text: ""
    property bool shown: false
    opacity: shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }

    function show(k, i, p, t) {
        kind = k; icon = i; percent = p; text = t
        shown = true
        hide.restart()
    }
    Timer { id: hide; interval: 1500; onTriggered: osd.shown = false }
    Connections { target: DesktopPrompts; function onOsd(k, i, p, t) { osd.show(k, i, p, t) } }

    Surface {
        anchors.fill: parent
        kind: Surface.Strong
        radius: height / 2
        elevation: 2
    }
    Row {
        anchors { fill: parent; leftMargin: Theme.space5; rightMargin: Theme.space5 }
        spacing: Theme.space3
        Icon { name: osd.icon; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
        // Jauge
        Rectangle {
            visible: osd.percent >= 0
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 16 - pctLabel.width - Theme.space3 * 2
            height: 6; radius: 3
            color: Theme.surfaceActive
            Rectangle {
                height: parent.height; radius: 3
                color: Theme.accent
                width: parent.width * Math.max(0, Math.min(100, osd.percent)) / 100
                Behavior on width { NumberAnimation { duration: Theme.durFast } }
            }
        }
        Label {
            id: pctLabel
            visible: osd.percent >= 0
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            horizontalAlignment: Text.AlignRight
            text: osd.percent + " %"
            font.weight: Font.DemiBold
        }
        Label {
            visible: osd.percent < 0
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 16 - Theme.space3
            text: osd.text
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }
}
