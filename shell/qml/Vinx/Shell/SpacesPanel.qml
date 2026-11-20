import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Menu des espaces de travail (ADR 0044), ouvert depuis les points de la barre.
// Un espace = un bureau virtuel de KWin. Liste : numéro, nom, raccourci Méta+N ; clic pour y aller.
// « Modifier » : renommer (Entrée) et supprimer ; « Nouvel espace » en ajoute un et propose son nom.
Column {
    id: panel
    width: 300
    spacing: Theme.space1
    signal done()

    readonly property var backend: Tasks.backend
    readonly property int count: backend ? backend.desktopCount : 0
    readonly property int current: backend ? backend.currentDesktopIndex : 0
    readonly property var names: backend && backend.desktopNames ? backend.desktopNames : []
    property bool editing: false
    property int focusIndex: -1          // champ de nom à activer après « Nouvel espace »
    property int paletteFor: -1          // espace dont on choisit la couleur (mode « Modifier »)
    onEditingChanged: if (!editing) paletteFor = -1
    // Accent global (vert par défaut) : couleur des espaces sans couleur propre.
    readonly property var globalAccent: { Preferences.revision; const id = String(Preferences.value("appearance/resolvedAccent", "")); return Theme.accents.find(a => a.id === id) || Theme.accents[0] }
    function fillOf(i) { const f = ShellState.spaceFill(i); return f !== "" ? f : globalAccent.fill }

    function reset() { editing = false; focusIndex = -1; paletteFor = -1 }
    function nameOf(i) {
        const n = String(names[i] || "")
        return n !== "" ? n : qsTr("Espace %1").arg(i + 1)
    }
    function addSpace() {
        if (!backend) return
        const i = count
        backend.addDesktop()
        backend.renameDesktop(i, qsTr("Espace %1").arg(i + 1))
        editing = true
        focusIndex = i
    }

    Label {
        leftPadding: Theme.space2
        topPadding: Theme.space1
        bottomPadding: Theme.space1
        text: qsTr("Espaces")
        level: Label.Tertiary
        font.pixelSize: Theme.fsXs
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.6
    }

    Repeater {
        model: panel.count
        delegate: Rectangle {
            id: row
            required property int index
            readonly property bool isCurrent: index === panel.current
            width: panel.width
            height: 44
            radius: Theme.radiusMd
            color: isCurrent ? Theme.surfaceActive : rowMouse.containsMouse && !panel.editing ? Theme.surfaceHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durFast } }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !panel.editing
                onClicked: { panel.backend.activateDesktop(row.index); panel.done() }
            }
            Accessible.role: Accessible.Button
            Accessible.name: panel.nameOf(row.index)

            // Numéro de l'espace, dans une petite tuile (bord accentué pour l'espace courant).
            Rectangle {
                id: badge
                anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                width: 30; height: 22; radius: 6
                // Pastille à la couleur de l'espace (ADR 0044) : pleine pour l'espace courant.
                readonly property color fill: (ShellState.spaceColors, panel.backend.desktopIds, panel.fillOf(row.index))
                color: row.isCurrent ? fill : Theme.surfaceSunken
                border.width: 2
                border.color: fill
                Label {
                    anchors.centerIn: parent; text: row.index + 1; font.pixelSize: Theme.fsSm; font.weight: Font.DemiBold
                    color: row.isCurrent ? (Theme.accents.find(a => a.fill === String(badge.fill).toUpperCase()) || Theme.accents[0]).ink : Theme.text
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: panel.editing
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.paletteFor = panel.paletteFor === row.index ? -1 : row.index
                }
                Accessible.role: panel.editing ? Accessible.Button : Accessible.StaticText
                Accessible.name: qsTr("Couleur de l'espace %1").arg(row.index + 1)
            }

            Label {
                visible: !panel.editing
                anchors { left: badge.right; leftMargin: Theme.space3; right: key.left; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                text: panel.nameOf(row.index)
                font.weight: row.isCurrent ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
            Label {
                id: key
                visible: !panel.editing && row.index < 9
                anchors { right: parent.right; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
                text: qsTr("Méta+%1").arg(row.index + 1)
                level: Label.Tertiary
                font.pixelSize: Theme.fsXs
            }

            // Mode « Modifier » : champ de nom et suppression.
            Rectangle {
                visible: panel.editing
                anchors { left: badge.right; leftMargin: Theme.space3; right: del.left; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                height: 30
                radius: Theme.radiusSm
                color: Theme.surfaceSunken
                border.width: field.activeFocus ? 2 : 1
                border.color: field.activeFocus ? Theme.accentForeground : Theme.border
                TextInput {
                    id: field
                    objectName: "spaceName" + row.index
                    anchors { fill: parent; leftMargin: Theme.space2; rightMargin: Theme.space2 }
                    verticalAlignment: TextInput.AlignVCenter
                    text: panel.nameOf(row.index)
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fsMd
                    maximumLength: 40
                    clip: true
                    Accessible.name: qsTr("Nom de l'espace %1").arg(row.index + 1)
                    function commit() {
                        const t = text.trim()
                        if (t !== "" && t !== String(panel.names[row.index] || "")) panel.backend.renameDesktop(row.index, t)
                    }
                    onEditingFinished: commit()
                    Keys.onReturnPressed: { commit(); panel.editing = false }
                    Keys.onEscapePressed: { text = panel.nameOf(row.index); panel.editing = false }
                    Component.onCompleted: if (panel.focusIndex === row.index) { forceActiveFocus(); selectAll(); panel.focusIndex = -1 }
                    Connections {
                        target: panel
                        function onFocusIndexChanged() { if (panel.focusIndex === row.index) { field.forceActiveFocus(); field.selectAll(); panel.focusIndex = -1 } }
                    }
                }
            }
            IconButton {
                id: del
                visible: panel.editing
                enabled: panel.count > 1
                anchors { right: parent.right; rightMargin: Theme.space1; verticalCenter: parent.verticalCenter }
                iconName: "trash"
                flat: true
                toolTip: qsTr("Supprimer l'espace (ses fenêtres vont dans un espace voisin)")
                onClicked: panel.backend.removeDesktopAt(row.index)
            }
        }
    }

    // Palette de l'espace choisi : « Par défaut » (accent global, vert) puis les 8 accents.
    Column {
        visible: panel.editing && panel.paletteFor >= 0 && panel.paletteFor < panel.count
        width: panel.width
        spacing: Theme.space2
        topPadding: Theme.space1
        bottomPadding: Theme.space2
        Label {
            leftPadding: Theme.space2
            text: qsTr("Couleur de « %1 »").arg(panel.nameOf(Math.max(0, panel.paletteFor)))
            level: Label.Secondary
            font.pixelSize: Theme.fsSm
        }
        Flow {
            x: Theme.space2
            width: panel.width - Theme.space2 * 2
            spacing: 8
            Repeater {
                model: [""].concat(Theme.accents.map(a => a.id))
                delegate: Rectangle {
                    id: sw
                    required property string modelData
                    readonly property var entry: modelData === "" ? panel.globalAccent : Theme.accents.find(a => a.id === modelData)
                    readonly property bool chosen: (ShellState.spaceColors, ShellState.spaceColorAt(panel.paletteFor)) === modelData
                    objectName: "swatch_" + (modelData || "default")
                    width: modelData === "" ? defLabel.implicitWidth + 22 : 26; height: 26; radius: 13
                    color: entry.fill
                    border.width: chosen ? 2 : 0
                    border.color: Theme.text
                    Rectangle {      // anneau intérieur blanc quand choisie
                        visible: sw.chosen
                        anchors { fill: parent; margins: 2 }
                        radius: width / 2
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.surfaceGlassStrong
                    }
                    Label {
                        id: defLabel
                        visible: sw.modelData === ""
                        anchors.centerIn: parent
                        text: qsTr("Par défaut")
                        font.pixelSize: Theme.fsXs
                        font.weight: Font.DemiBold
                        color: sw.entry.ink
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellState.setSpaceColorAt(panel.paletteFor, sw.modelData) }
                    Accessible.role: Accessible.RadioButton
                    Accessible.checked: chosen
                    Accessible.name: sw.modelData === "" ? qsTr("Par défaut (%1)").arg(panel.globalAccent.name) : sw.entry.name
                }
            }
        }
    }

    Label {
        visible: panel.editing && panel.paletteFor < 0
        width: panel.width
        leftPadding: Theme.space2
        rightPadding: Theme.space2
        bottomPadding: Theme.space1
        wrapMode: Text.WordWrap
        text: qsTr("Cliquez sur le numéro d'un espace pour choisir sa couleur.")
        level: Label.Tertiary
        font.pixelSize: Theme.fsXs
    }

    Rectangle { width: panel.width; height: 1; color: Theme.border; opacity: 0.8 }

    Row {
        spacing: Theme.space2
        topPadding: Theme.space1
        Button {
            objectName: "addSpace"
            width: (panel.width - Theme.space2) / 2
            text: qsTr("Nouvel espace")
            iconName: "plus"
            onClicked: panel.addSpace()
        }
        Button {
            objectName: "editSpaces"
            width: (panel.width - Theme.space2) / 2
            text: panel.editing ? qsTr("Terminé") : qsTr("Modifier")
            variant: panel.editing ? Button.Primary : Button.Secondary
            onClicked: panel.editing = !panel.editing
        }
    }
}
