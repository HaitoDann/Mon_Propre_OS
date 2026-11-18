import QtQuick
import Vinx.Theme
import Vinx.Controls

// Bouton texte des barres posées sur l'image (fond sombre, quel que soit le thème).
Rectangle {
    id: root
    property string text
    property string toolTip
    property bool checked: false
    property bool primary: false
    signal clicked()
    implicitWidth: label.implicitWidth + Theme.space3 * 2
    implicitHeight: 34
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    radius: Theme.radiusSm
    opacity: enabled ? 1 : 0.4
    color: primary ? Theme.accent : checked ? "#1FFFFFFF" : mouse.containsMouse ? "#14FFFFFF" : "transparent"
    activeFocusOnTab: true
    Keys.onSpacePressed: clicked()
    Accessible.role: Accessible.Button
    Accessible.name: toolTip || text
    Label {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: Theme.fsMd
        font.weight: root.primary ? Font.DemiBold : Font.Normal
        color: root.primary ? Theme.accentForeground : root.checked ? "#FFFFFF" : "#D8D8D6"
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
