import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.Files

// Vue en icônes.
GridView {
    id: grid
    property var host
    signal contextMenu(int index, real x, real y)
    readonly property int columns: Math.max(1, Math.floor(width / cellWidth))
    function positionAt(i) { positionViewAtIndex(i, GridView.Contain) }

    clip: true
    leftMargin: Theme.space3; rightMargin: Theme.space3; topMargin: Theme.space3; bottomMargin: Theme.space3
    cellWidth: 112; cellHeight: 112
    boundsBehavior: Flickable.StopAtBounds
    keyNavigationEnabled: false
    interactive: true

    MouseArea {
        z: -1
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (m) => { grid.forceActiveFocus(); if (m.button === Qt.RightButton) grid.contextMenu(-1, m.x, m.y); else grid.host.clearSelection() }
    }

    delegate: Item {
        id: cell
        required property int index
        required property string name
        required property url url
        required property bool isDir
        required property bool isImage
        required property string iconName
        readonly property bool selected: grid.host.selected[name] === true
        width: grid.cellWidth; height: grid.cellHeight

        Rectangle {
            anchors { fill: parent; margins: 3 }
            radius: Theme.radiusMd
            color: cell.selected ? Theme.surfaceActive : ma.containsMouse ? Theme.surfaceHover : "transparent"
            border.width: grid.host.current === cell.index && grid.activeFocus ? 1 : 0
            border.color: Theme.accentForeground
        }
        FileIcon {
            id: icon
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 10 }
            size: 52
            iconName: cell.iconName; url: cell.url; isDir: cell.isDir; isImage: cell.isImage
        }
        Label {
            visible: grid.host.renaming !== cell.name
            anchors { top: icon.bottom; topMargin: 6; left: parent.left; right: parent.right; margins: 6 }
            text: cell.name
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fsSm
            wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideMiddle
        }
        Loader {
            active: grid.host.renaming === cell.name
            anchors { top: icon.bottom; topMargin: 4; left: parent.left; right: parent.right; margins: 4 }
            sourceComponent: RenameField { name: cell.name; url: cell.url; onFinished: { grid.host.renaming = ""; grid.forceActiveFocus() } }
        }
        // Glisser : la sélection part comme liste d'URL (vers Fichiers ou une autre application).
        Item {
            id: dragProxy
            Drag.active: ma.drag.active
            Drag.dragType: Drag.Automatic
            Drag.supportedActions: Qt.MoveAction | Qt.CopyAction
            Drag.proposedAction: Qt.MoveAction
            Drag.mimeData: ({ "text/uri-list": (grid.host.selected, grid.host.selectedUrls().map(u => u.toString()).join("\r\n")) })
        }
        // Déposer sur un dossier : y déplacer (ou copier avec Ctrl).
        DropArea {
            id: folderDrop
            anchors.fill: parent
            enabled: cell.isDir
            keys: ["text/uri-list"]
            onDropped: (d) => { grid.host.dropUrls(d.urls, cell.url, d.proposedAction === Qt.CopyAction || (d.modifiers & Qt.ControlModifier)); d.accept() }
        }
        Rectangle {
            visible: folderDrop.containsDrag
            anchors { fill: parent; margins: 3 }
            radius: Theme.radiusMd
            color: "transparent"
            border.width: 2; border.color: Theme.accentForeground
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            enabled: grid.host.renaming !== cell.name
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            drag.target: dragProxy
            drag.threshold: 8
            onPressed: (m) => {
                grid.forceActiveFocus()
                if (m.button === Qt.RightButton) return
                if (m.button === Qt.MiddleButton) { if (cell.isDir) grid.host.newTab(cell.url); return }
                // Clic sur un élément déjà seul sélectionné : renommage après un court délai (comme ailleurs).
                grid.host.select(cell.index, m.modifiers)
            }
            onClicked: (m) => { if (m.button === Qt.RightButton) grid.contextMenu(cell.index, cell.x + m.x - grid.contentX, cell.y + m.y - grid.contentY) }
            onReleased: dragProxy.x = dragProxy.y = 0
            onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) grid.host.activate(cell.index) }
        }
    }
}
