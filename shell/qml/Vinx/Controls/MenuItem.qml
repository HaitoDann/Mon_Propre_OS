import QtQuick
import Vinx.Theme
import Vinx.Controls  // types C++ du module (Icon) — import explicite requis avant Qt 6.5

// Entrée de menu : texte, icône, coche et raccourci optionnels ;
// ou séparateur / en-tête de section.
Item {
    id: root
    property string text
    property string iconName
    property string shortcut
    property var checked: undefined       // undefined = pas de case ; true/false sinon
    property bool separator: false
    property bool header: false
    signal triggered()

    readonly property bool interactive: enabled && !separator && !header
    implicitHeight: separator ? 9 : header ? 24 : 26
    implicitWidth: separator ? 0 : row.implicitWidth + Theme.space2 * 2

    Rectangle {
        visible: root.separator
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.space2 }
        height: 1
        color: Theme.border
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusXs
        color: root.interactive && mouse.containsMouse ? Theme.surfaceActive : "transparent"
    }

    Row {
        id: row
        visible: !root.separator
        anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter }
        spacing: Theme.space2
        readonly property color fg: root.header ? Theme.textTertiary
                                  : !root.enabled ? Theme.textTertiary
                                  : Theme.text
        Item {
            visible: root.checked !== undefined
            width: 14; height: 14
            anchors.verticalCenter: parent.verticalCenter
            Icon { anchors.fill: parent; name: "check"; color: row.fg; visible: root.checked === true }
        }
        Icon {
            visible: root.iconName !== ""
            name: root.iconName
            width: 16; height: 16
            color: row.fg
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            text: root.header ? root.text.toUpperCase() : root.text
            color: row.fg
            font.pixelSize: root.header ? Theme.fsXs : Theme.fsMd
            font.weight: root.header ? Font.DemiBold : Font.Normal
            font.letterSpacing: root.header ? 0.5 : 0
            anchors.verticalCenter: parent.verticalCenter
        }
        Item { width: root.shortcut ? Theme.space5 : 0; height: 1 }
    }
    Label {
        visible: root.shortcut !== "" && !root.separator
        anchors { right: parent.right; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter }
        text: root.shortcut
        font.pixelSize: Theme.fsSm
        color: Theme.textTertiary
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive
        onClicked: root.triggered()
    }
}
