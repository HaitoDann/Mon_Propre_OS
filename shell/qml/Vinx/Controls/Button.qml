import QtQuick
import Vinx.Theme
import Vinx.Controls  // types C++ du module (Icon) — import explicite requis avant Qt 6.5

// Bouton texte, avec icône optionnelle. Variantes : Primary (accent), Secondary, Ghost.
Item {
    id: root
    enum Variant { Primary, Secondary, Ghost }
    property int variant: Button.Secondary
    property string text
    property string iconName
    property bool pill: false
    signal clicked()

    implicitHeight: 28
    implicitWidth: row.implicitWidth + Theme.space3 * 2
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.45

    Keys.onSpacePressed: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: text

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.pill ? height / 2 : Theme.radiusSm
        color: root.variant === Button.Primary ? Theme.accent
             : root.variant === Button.Ghost ? (mouse.containsMouse ? Theme.surfaceHover : "transparent")
             : (mouse.pressed ? Theme.surfaceActive : mouse.containsMouse ? Theme.surfaceActive : Theme.surfaceHover)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        // Assombrit / éclaircit le bouton principal au survol et à l'appui.
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            visible: root.variant === Button.Primary
            color: mouse.pressed ? "#26000000" : mouse.containsMouse ? "#18FFFFFF" : "transparent"
        }
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accentForeground
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.space2
        Icon {
            visible: root.iconName !== ""
            name: root.iconName
            width: 16; height: 16
            anchors.verticalCenter: parent.verticalCenter
            color: label.color
        }
        Label {
            id: label
            text: root.text
            font.weight: Font.Medium
            color: root.variant === Button.Primary ? Theme.accentText : Theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
