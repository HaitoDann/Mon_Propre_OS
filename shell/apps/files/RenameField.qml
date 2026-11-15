import QtQuick
import Vinx.Theme
import Vinx.Files

// Champ de renommage en place : Entrée valide, Échap annule ; le nom sans
// l'extension est présélectionné.
Rectangle {
    id: root
    property string name
    property url url
    signal finished()
    radius: Theme.radiusXs
    color: Theme.surfaceWindow
    border.width: 2; border.color: Theme.accentForeground
    height: 24
    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        color: Theme.text; font.pixelSize: Theme.fsSm; clip: true
        selectByMouse: true
        text: root.name
        Component.onCompleted: {
            const dot = text.lastIndexOf(".")
            select(0, dot > 0 ? dot : text.length)
            forceActiveFocus()
        }
        onAccepted: { if (text.trim() && text !== root.name) FileOps.rename(root.url, text); root.finished() }
        Keys.onEscapePressed: root.finished()
        onActiveFocusChanged: if (!activeFocus) root.finished()
    }
}
