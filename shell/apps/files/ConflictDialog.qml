import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.Files

// Conflit de noms lors d'une copie ou d'un déplacement : Remplacer, Garder les deux, Ignorer.
Rectangle {
    id: root
    property var urls: []
    property url dest
    property bool moving: false
    property var names: []
    function ask(urls, dest, moving) {
        const c = FileOps.conflicts(urls, dest)
        if (!c.length) return run(urls, dest, moving, FileOps.KeepBoth)
        root.urls = urls; root.dest = dest; root.moving = moving; root.names = c
        visible = true
        keepButton.forceActiveFocus()
    }
    function run(urls, dest, moving, mode) {
        if (moving) FileOps.move(urls, dest, mode); else FileOps.copy(urls, dest, mode)
    }
    function choose(mode) { visible = false; run(urls, dest, moving, mode) }

    visible: false
    anchors.fill: parent
    color: "#66000000"
    z: 200
    MouseArea { anchors.fill: parent }   // bloque les clics derrière
    Keys.onEscapePressed: visible = false

    Surface {
        anchors.centerIn: parent
        width: 440
        height: col.height + Theme.space5 * 2
        radius: Theme.radiusLg
        Column {
            id: col
            x: Theme.space5; y: Theme.space5
            width: parent.width - Theme.space5 * 2
            spacing: Theme.space3
            Label {
                text: root.names.length === 1 ? qsTr("« %1 » existe déjà").arg(root.names[0])
                                              : qsTr("%n éléments existent déjà", "", root.names.length)
                font.pixelSize: Theme.fsLg; font.weight: Font.DemiBold
                width: parent.width; elide: Text.ElideMiddle
            }
            Label {
                text: qsTr("Un élément du même nom se trouve déjà dans ce dossier. Que voulez-vous faire ?")
                level: Label.Secondary; wrapMode: Text.WordWrap; width: parent.width
            }
            Row {
                spacing: Theme.space2
                anchors.right: parent.right
                topPadding: Theme.space2
                Button { text: qsTr("Ignorer"); variant: Button.Ghost; onClicked: root.choose(FileOps.Skip) }
                Button { text: qsTr("Remplacer"); variant: Button.Secondary; onClicked: root.choose(FileOps.Replace) }
                Button { id: keepButton; text: qsTr("Garder les deux"); variant: Button.Primary; onClicked: root.choose(FileOps.KeepBoth) }
            }
        }
    }
}
