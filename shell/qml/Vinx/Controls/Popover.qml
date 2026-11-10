import QtQuick
import Vinx.Theme

// Panneau flottant ancré sur un élément (menus, centre de contrôle, calendrier).
// À placer dans une couche qui recouvre la fenêtre : il remplit son parent,
// intercepte le clic extérieur (fermeture) et se positionne sous / sur l'ancre.
Item {
    id: root
    enum Edge { Below, Above }
    enum Align { Start, Center, End }

    property bool open: false
    property Item anchorItem
    // Zone d'ancrage en coordonnées du popover, si l'ancre est dans une autre fenêtre (shell).
    property rect anchorRect
    property int edge: Popover.Below
    property int align: Popover.Start
    property int padding: Theme.space1
    property bool closeOnOutsideClick: true
    default property alias content: body.data
    signal closed()

    function show(item) {
        if (item) anchorItem = item
        reposition()
        Qt.callLater(reposition)   // la taille du contenu peut n'être connue qu'après une passe
        open = true
        forceActiveFocus()
    }
    function close() { if (open) { open = false; closed() } }
    function toggle(item) { open ? close() : show(item) }

    function reposition() {
        let a
        if (anchorItem) {
            const p = anchorItem.mapToItem(root, 0, 0)
            a = Qt.rect(p.x, p.y, anchorItem.width, anchorItem.height)
        } else if (anchorRect.width > 0) {
            a = anchorRect
        } else return
        let x = align === Popover.End ? a.x + a.width - panel.width
              : align === Popover.Center ? a.x + (a.width - panel.width) / 2 : a.x
        panel.x = Math.max(8, Math.min(x, width - panel.width - 8))
        panel.y = edge === Popover.Above ? a.y - panel.height - 6 : a.y + a.height + 6
    }

    anchors.fill: parent
    z: 1000
    onWidthChanged: if (open) reposition()
    onHeightChanged: if (open) reposition()
    visible: panel.opacity > 0
    Keys.onEscapePressed: close()

    MouseArea {
        anchors.fill: parent
        enabled: root.open && root.closeOnOutsideClick
        onPressed: root.close()
    }

    Surface {
        id: panel
        kind: Surface.Strong
        elevation: 2
        width: body.childrenRect.width + root.padding * 2
        height: body.childrenRect.height + root.padding * 2
        onWidthChanged: root.reposition()
        onHeightChanged: root.reposition()

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.97
        transformOrigin: root.edge === Popover.Above ? Item.Bottom : Item.Top
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
        Behavior on scale { NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }   // les clics dans le panneau ne le ferment pas
        Item {
            id: body
            x: root.padding; y: root.padding
            width: childrenRect.width; height: childrenRect.height
        }
    }
}
