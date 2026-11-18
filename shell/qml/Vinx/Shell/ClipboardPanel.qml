import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Historique du presse-papiers (Méta+V, ADR 0037) : les 50 derniers textes, liens et images,
// épinglables. Entrée remet l'élément dans le presse-papiers ; Ctrl+V le colle ensuite.
Column {
    id: panel
    width: 460
    spacing: Theme.space2
    signal done()

    property int selected: 0
    property real now: Date.now()
    readonly property var shown: {
        const q = field.text.trim().toLowerCase()
        return Clipboard.items.filter(i => !q || (i.kind !== "image" && i.text.toLowerCase().includes(q)))
    }

    function reset() {
        field.text = ""
        selected = 0
        now = Date.now()
        field.forceActiveFocus()
    }
    function ago(t) {
        const s = Math.max(0, (now - t) / 1000)
        if (s < 60) return qsTr("À l'instant")
        if (s < 3600) return qsTr("Il y a %1 min").arg(Math.floor(s / 60))
        if (s < 86400) return qsTr("Il y a %1 h").arg(Math.floor(s / 3600))
        return new Date(t).toLocaleDateString(Qt.locale(), Locale.ShortFormat)
    }
    function activate(i) {
        const it = shown[i]
        if (!it) return
        Clipboard.activate(it.id)
        done()
    }

    // ---------- Recherche ----------
    Rectangle {
        width: parent.width; height: 40
        radius: Theme.radiusMd
        color: Theme.surfaceHover
        Icon { id: lens; name: "search"; width: 16; height: 16; color: Theme.textSecondary; anchors { left: parent.left; leftMargin: Theme.space3; verticalCenter: parent.verticalCenter } }
        TextInput {
            id: field
            objectName: "clipboardSearch"
            anchors { left: lens.right; leftMargin: Theme.space2; right: parent.right; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsLg
            color: Theme.text
            selectionColor: Theme.accent
            clip: true
            onTextChanged: panel.selected = 0
            Keys.onDownPressed: panel.selected = Math.min(panel.shown.length - 1, panel.selected + 1)
            Keys.onUpPressed: panel.selected = Math.max(0, panel.selected - 1)
            Keys.onReturnPressed: panel.activate(panel.selected)
            Keys.onEnterPressed: panel.activate(panel.selected)
            Keys.onEscapePressed: panel.done()
            Keys.onDeletePressed: (e) => {
                if (field.text === "" && panel.shown[panel.selected]) Clipboard.remove(panel.shown[panel.selected].id)
                else e.accepted = false
            }
            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_P && (e.modifiers & Qt.ControlModifier) && panel.shown[panel.selected]) {
                    const it = panel.shown[panel.selected]
                    Clipboard.setPinned(it.id, !it.pinned)
                    e.accepted = true
                }
            }
            Label {
                visible: field.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Rechercher dans l'historique…")
                level: Label.Tertiary
                font.pixelSize: Theme.fsLg
            }
        }
    }

    // ---------- Éléments ----------
    ListView {
        id: list
        width: parent.width
        height: Math.min(contentHeight, 7 * 56)
        clip: true
        model: panel.shown
        currentIndex: panel.selected
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
        boundsBehavior: Flickable.StopAtBounds
        delegate: Rectangle {
            id: row
            required property int index
            required property var modelData
            width: ListView.view.width
            height: 56
            radius: Theme.radiusMd
            color: index === panel.selected ? Theme.surfaceActive : mouse.containsMouse ? Theme.surfaceHover : "transparent"
            Rectangle {
                id: badge
                anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                width: 40; height: 40
                radius: Theme.radiusSm
                color: Theme.surfaceSunken
                border.width: 1; border.color: Theme.border
                clip: true
                Image {
                    anchors.fill: parent
                    visible: row.modelData.kind === "image"
                    source: row.modelData.thumbnail || ""
                    fillMode: Image.PreserveAspectCrop
                }
                Icon {
                    anchors.centerIn: parent
                    visible: row.modelData.kind !== "image"
                    width: 18; height: 18
                    name: row.modelData.kind === "link" ? "globe" : "doc"
                    color: Theme.textSecondary
                }
            }
            Column {
                anchors { left: badge.right; leftMargin: Theme.space3; right: pin.left; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.weight: Font.Medium
                    text: row.modelData.kind === "image" ? qsTr("Image %1").arg(row.modelData.text) : row.modelData.text.replace(/\s+/g, " ").trim()
                }
                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    level: Label.Tertiary
                    font.pixelSize: Theme.fsSm
                    text: panel.ago(row.modelData.time) + (row.modelData.pinned ? " · " + qsTr("épinglé") : "")
                }
            }
            MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: panel.activate(row.index) }
            // Épingler : pastille pleine à l'accent quand l'élément est gardé.
            Item {
                id: pin
                anchors { right: parent.right; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                width: 32; height: 32
                Rectangle {
                    anchors.centerIn: parent
                    width: 12; height: 12; radius: 6
                    color: row.modelData.pinned ? Theme.accent : "transparent"
                    border.width: row.modelData.pinned ? 0 : 1.5
                    border.color: pinMouse.containsMouse ? Theme.text : Theme.textTertiary
                    visible: row.modelData.pinned || mouse.containsMouse || pinMouse.containsMouse || row.index === panel.selected
                }
                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Clipboard.setPinned(row.modelData.id, !row.modelData.pinned)
                }
                Accessible.role: Accessible.CheckBox
                Accessible.name: qsTr("Épingler")
                Accessible.checked: row.modelData.pinned
            }
        }
    }
    Column {
        visible: panel.shown.length === 0
        width: parent.width
        topPadding: Theme.space4
        bottomPadding: Theme.space4
        spacing: Theme.space1
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: field.text ? qsTr("Aucun élément ne correspond.") : qsTr("Rien n'a encore été copié.")
            level: Label.Secondary
        }
        Label {
            visible: !field.text
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - Theme.space6 * 2
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: qsTr("Ce que vous copiez apparaîtra ici. L'historique est effacé à la fermeture de session, sauf les éléments épinglés.")
            level: Label.Tertiary
            font.pixelSize: Theme.fsSm
        }
    }

    // ---------- Pied ----------
    Item {
        width: parent.width; height: 28
        Label {
            anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter }
            text: qsTr("Entrée : copier, puis Ctrl+V pour coller · Ctrl+P : épingler")
            level: Label.Tertiary
            font.pixelSize: Theme.fsXs
        }
        Button {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: Clipboard.items.some(i => !i.pinned)
            text: qsTr("Tout effacer")
            variant: Button.Ghost
            onClicked: Clipboard.clear()
        }
    }
}
