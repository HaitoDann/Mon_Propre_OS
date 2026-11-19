import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.Files

// Vue en liste : nom, date de modification, taille, type.
ListView {
    id: list
    property var host
    signal contextMenu(int index, real x, real y)
    readonly property int columns: 1
    function positionAt(i) { positionViewAtIndex(i, ListView.Contain) }

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    keyNavigationEnabled: false
    headerPositioning: ListView.OverlayHeader
    readonly property real dateWidth: 150
    readonly property real sizeWidth: 90

    header: Rectangle {
        width: list.width; height: 30; z: 2
        color: Theme.surfaceWindow
        Label { text: qsTr("Nom"); level: Label.Tertiary; font.pixelSize: Theme.fsSm; anchors { left: parent.left; leftMargin: Theme.space4 + 28; verticalCenter: parent.verticalCenter } }
        Label { text: qsTr("Modifié"); level: Label.Tertiary; font.pixelSize: Theme.fsSm; x: list.width - list.sizeWidth - list.dateWidth - Theme.space4; anchors.verticalCenter: parent.verticalCenter }
        Label { text: qsTr("Taille"); level: Label.Tertiary; font.pixelSize: Theme.fsSm; width: list.sizeWidth; horizontalAlignment: Text.AlignRight; x: list.width - list.sizeWidth - Theme.space4; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
    }

    MouseArea {
        z: -1
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (m) => { list.forceActiveFocus(); if (m.button === Qt.RightButton) list.contextMenu(-1, m.x, m.y); else list.host.clearSelection() }
    }

    delegate: Item {
        id: row
        required property int index
        required property string name
        required property url url
        required property bool isDir
        required property bool isImage
        required property string iconName
        required property string sizeText
        required property var modified
        readonly property bool selected: list.host.selected[name] === true
        width: list.width; height: 32

        Rectangle {
            anchors { fill: parent; leftMargin: Theme.space2; rightMargin: Theme.space2 }
            radius: Theme.radiusSm
            color: row.selected ? Theme.surfaceActive : ma.containsMouse ? Theme.surfaceHover : "transparent"
            border.width: list.host.current === row.index && list.activeFocus ? 1 : 0
            border.color: Theme.accentForeground
        }
        FileIcon {
            id: icon
            anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
            size: 20
            iconName: row.iconName; url: row.url; isDir: row.isDir; isImage: false
        }
        Label {
            visible: list.host.renaming !== row.name
            anchors { left: icon.right; leftMargin: Theme.space2; right: date.left; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            text: row.name; elide: Text.ElideMiddle
        }
        Loader {
            active: list.host.renaming === row.name
            anchors { left: icon.right; leftMargin: Theme.space2; right: date.left; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            sourceComponent: RenameField { name: row.name; url: row.url; onFinished: { list.host.renaming = ""; list.forceActiveFocus() } }
        }
        Label {
            id: date
            x: list.width - list.sizeWidth - list.dateWidth - Theme.space4
            width: list.dateWidth
            anchors.verticalCenter: parent.verticalCenter
            text: row.modified ? Qt.formatDateTime(row.modified, "dd/MM/yyyy HH:mm") : ""
            level: Label.Secondary; font.pixelSize: Theme.fsSm
        }
        Label {
            x: list.width - list.sizeWidth - Theme.space4
            width: list.sizeWidth; horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
            text: row.isDir ? "—" : row.sizeText
            level: Label.Secondary; font.pixelSize: Theme.fsSm
        }
        // Glisser : la sélection part comme liste d'URL (vers Fichiers ou une autre application).
        Item {
            id: dragProxy
            // Lancé à la main (et non « Drag.active: ma.drag.active ») : le glisser automatique est
            // bloquant et remet active à false pendant la liaison, d'où une boucle signalée par Qt.
            Connections {
                target: ma.drag
                function onActiveChanged() { if (ma.drag.active) dragProxy.Drag.startDrag() }
            }
            Drag.dragType: Drag.Automatic
            Drag.supportedActions: Qt.MoveAction | Qt.CopyAction
            Drag.proposedAction: Qt.MoveAction
            Drag.mimeData: ({ "text/uri-list": (list.host.selected, list.host.selectedUrls().map(u => u.toString()).join("\r\n")) })
        }
        // Déposer sur un dossier : y déplacer (ou copier avec Ctrl).
        DropArea {
            id: folderDrop
            anchors.fill: parent
            enabled: row.isDir
            keys: ["text/uri-list"]
            onDropped: (d) => { list.host.dropUrls(d.urls, row.url, d.proposedAction === Qt.CopyAction || (d.modifiers & Qt.ControlModifier)); d.accept() }
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
            enabled: list.host.renaming !== row.name
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            drag.target: dragProxy
            drag.threshold: 8
            onPressed: (m) => {
                list.forceActiveFocus()
                if (m.button === Qt.MiddleButton) { if (row.isDir) list.host.newTab(row.url); return }
                if (m.button !== Qt.RightButton) list.host.select(row.index, m.modifiers)
            }
            onClicked: (m) => { if (m.button === Qt.RightButton) list.contextMenu(row.index, m.x, row.y + m.y - list.contentY) }
            onReleased: dragProxy.x = dragProxy.y = 0
            onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) list.host.activate(row.index) }
        }
    }
}
