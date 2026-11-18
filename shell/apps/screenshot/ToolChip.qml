import QtQuick
import Vinx.Theme
import Vinx.Controls

// Bouton texte compact des barres d'outils de la capture.
Rectangle {
    id: root
    property string text
    property bool checked: false
    property bool primary: false
    signal clicked()
    implicitWidth: label.implicitWidth + Theme.space3 * 2
    implicitHeight: 32
    radius: Theme.radiusSm
    opacity: enabled ? 1 : 0.45
    color: primary ? Theme.accent : checked ? Theme.surfaceActive : mouse.containsMouse ? Theme.surfaceHover : "transparent"
    activeFocusOnTab: true
    Keys.onSpacePressed: clicked()
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.checked: checked
    Label {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: Theme.fsMd
        font.weight: root.primary || root.checked ? Font.DemiBold : Font.Normal
        color: root.primary ? Theme.accentForeground : root.checked ? Theme.text : Theme.textSecondary
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
