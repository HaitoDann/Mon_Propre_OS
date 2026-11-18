import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.Shell
import Vinx.Screenshot

// Annotation de la capture : flèche, cadre, surlignage, flou, texte ; copier, enregistrer.
// Les annotations sont dessinées en pleine résolution par Shot (captureutil.h).
Window {
    id: win
    width: 1040; height: 700
    minimumWidth: 720; minimumHeight: 480
    title: qsTr("Capture d'écran")
    color: Theme.surfaceWindow
    AppearanceSync {}

    property string tool: "arrow"
    property color ink: colors[0]
    readonly property var colors: ["#FF5F57", "#FEBC2E", "#10DD8C", "#2E9BFF", "#141414"]
    property string status: Shot.mode === "edit" ? Shot.savedPath.split("/").pop() : qsTr("Copiée dans le presse-papiers.")

    // Coordonnées : vue → image d'origine.
    readonly property real scale: shot.paintedWidth > 0 ? Shot.imageWidth / shot.paintedWidth : 1
    readonly property real offsetX: (shot.width - shot.paintedWidth) / 2
    readonly property real offsetY: (shot.height - shot.paintedHeight) / 2
    function toImage(p) { return Qt.point((p.x - offsetX) * scale, (p.y - offsetY) * scale) }

    function copy() { Shot.copy(); status = qsTr("Copiée dans le presse-papiers.") }
    function save() {
        const path = Shot.save()
        status = path ? qsTr("Enregistrée dans Images › Captures.") : qsTr("L'enregistrement a échoué.")
    }

    Shortcut { sequences: [StandardKey.Copy]; enabled: !textEntry.visible; onActivated: win.copy() }
    Shortcut { sequences: [StandardKey.Save]; onActivated: win.save() }
    Shortcut { sequences: [StandardKey.Undo]; enabled: !textEntry.visible; onActivated: Shot.undo() }

    // ---------- Image ----------
    Rectangle {
        id: canvasArea
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: panel.left }
        color: Theme.surfaceSunken
        Image {
            id: shot
            anchors { fill: parent; margins: Theme.space5 }
            fillMode: Image.PreserveAspectFit
            source: Shot.hasImage ? "image://shot/capture/" + Shot.revision : ""
            cache: false
            asynchronous: false
            smooth: true
            mipmap: true
        }
        Rectangle {   // ombre légère sous l'image
            x: shot.x + win.offsetX; y: shot.y + win.offsetY; z: -1
            width: shot.paintedWidth; height: shot.paintedHeight
            color: "transparent"; border.width: 1; border.color: Theme.border
        }

        // Tracé en cours (aperçu) ; le rendu définitif vient de Shot.
        Canvas {
            id: preview
            anchors.fill: shot
            property point a
            property point b
            property bool drawing: false
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                if (!drawing) return
                const x = Math.min(a.x, b.x), y = Math.min(a.y, b.y), w = Math.abs(b.x - a.x), h = Math.abs(b.y - a.y)
                ctx.lineWidth = 3
                ctx.strokeStyle = win.ink
                if (win.tool === "arrow") { ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke() }
                else if (win.tool === "frame") ctx.strokeRect(x, y, w, h)
                else if (win.tool === "highlight") { ctx.fillStyle = Qt.rgba(win.ink.r, win.ink.g, win.ink.b, 0.35); ctx.fillRect(x, y, w, h) }
                else if (win.tool === "blur") { ctx.fillStyle = "#80808080"; ctx.fillRect(x, y, w, h); ctx.setLineDash([4, 4]); ctx.strokeStyle = "#606060"; ctx.strokeRect(x, y, w, h) }
            }
        }
        MouseArea {
            anchors.fill: shot
            cursorShape: win.tool === "text" ? Qt.IBeamCursor : Qt.CrossCursor
            onPressed: (m) => {
                if (win.tool === "text") { textEntry.open(m.x, m.y); return }
                preview.a = Qt.point(m.x, m.y); preview.b = preview.a; preview.drawing = true; preview.requestPaint()
            }
            onPositionChanged: (m) => { if (preview.drawing) { preview.b = Qt.point(m.x, m.y); preview.requestPaint() } }
            onReleased: {
                if (!preview.drawing) return
                preview.drawing = false
                preview.requestPaint()
                const p1 = win.toImage(preview.a), p2 = win.toImage(preview.b)
                if (Math.abs(p2.x - p1.x) + Math.abs(p2.y - p1.y) < 6) return
                Shot.addShape({ kind: win.tool, x1: p1.x, y1: p1.y, x2: p2.x, y2: p2.y, color: win.ink.toString() })
                win.status = ""
            }
        }
        // Saisie d'un texte à l'endroit cliqué.
        Rectangle {
            id: textEntry
            visible: false
            property point at
            function open(x, y) { at = Qt.point(x, y); field.text = ""; visible = true; field.forceActiveFocus() }
            function commit() {
                if (field.text.trim()) {
                    const p = win.toImage(Qt.point(at.x, at.y + 22))
                    Shot.addShape({ kind: "text", x1: p.x, y1: p.y, x2: p.x, y2: p.y, color: win.ink.toString(), text: field.text })
                }
                visible = false
            }
            x: shot.x + at.x; y: shot.y + at.y
            width: Math.max(160, field.contentWidth + 16); height: 30
            radius: Theme.radiusXs
            color: Theme.surfaceWindow
            border.width: 2; border.color: win.ink
            TextInput {
                id: field
                anchors { fill: parent; margins: 6 }
                color: Theme.text
                font.pixelSize: Theme.fsMd
                Keys.onReturnPressed: textEntry.commit()
                Keys.onEnterPressed: textEntry.commit()
                Keys.onEscapePressed: textEntry.visible = false
                onActiveFocusChanged: if (!activeFocus && textEntry.visible) textEntry.commit()
            }
        }
    }

    // ---------- Outils ----------
    Rectangle {
        id: panel
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: 236
        color: Theme.surfaceWindow
        Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.border }
        Column {
            anchors { fill: parent; margins: Theme.space4 }
            spacing: 4
            Repeater {
                model: [
                    { id: "arrow", glyph: "➚", text: qsTr("Flèche"), key: "1" },
                    { id: "frame", glyph: "▭", text: qsTr("Cadre"), key: "2" },
                    { id: "highlight", glyph: "▬", text: qsTr("Surligner"), key: "3" },
                    { id: "blur", glyph: "▦", text: qsTr("Flouter"), key: "4" },
                    { id: "text", glyph: "T", text: qsTr("Texte"), key: "5" }
                ]
                Rectangle {
                    id: toolRow
                    required property var modelData
                    width: parent.width; height: 34
                    radius: Theme.radiusSm
                    readonly property bool current: win.tool === modelData.id
                    color: current ? Theme.surfaceActive : toolMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    Row {
                        anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                        spacing: Theme.space2
                        Label { text: toolRow.modelData.glyph; width: 18; horizontalAlignment: Text.AlignHCenter; font.pixelSize: Theme.fsLg }
                        Label { text: toolRow.modelData.text; font.weight: toolRow.current ? Font.DemiBold : Font.Normal }
                    }
                    Label { anchors { right: parent.right; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter } text: toolRow.modelData.key; level: Label.Tertiary; font.pixelSize: Theme.fsXs }
                    MouseArea { id: toolMouse; anchors.fill: parent; hoverEnabled: true; onClicked: win.tool = toolRow.modelData.id }
                    Shortcut { sequence: toolRow.modelData.key; enabled: !textEntry.visible; onActivated: win.tool = toolRow.modelData.id }
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: modelData.text
                    Accessible.checked: current
                }
            }
            Row {
                spacing: 8
                leftPadding: Theme.space2
                topPadding: Theme.space2
                bottomPadding: Theme.space3
                Repeater {
                    model: win.colors
                    Rectangle {
                        required property string modelData
                        width: 22; height: 22; radius: 11
                        color: modelData
                        border.width: Qt.colorEqual(win.ink, modelData) ? 0 : (Theme.dark && modelData === "#141414" ? 1 : 0)
                        border.color: Theme.text
                        Rectangle { anchors.centerIn: parent; width: 30; height: 30; radius: 15; color: "transparent"; border.width: 2; border.color: Theme.text; visible: Qt.colorEqual(win.ink, parent.modelData) }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.ink = parent.modelData }
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: modelData
                    }
                }
            }
            Rectangle { width: parent.width; height: 1; color: Theme.border }
            Item { width: 1; height: Theme.space2 }
            Button { objectName: "copyButton"; width: parent.width; text: qsTr("Copier"); variant: Button.Primary; onClicked: win.copy() }
            Button { width: parent.width; text: qsTr("Enregistrer dans Images"); onClicked: win.save() }
            Button { width: parent.width; text: qsTr("Annuler la dernière annotation"); variant: Button.Ghost; enabled: Shot.canUndo; onClicked: Shot.undo() }
        }
        Column {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.space4 }
            spacing: Theme.space2
            Label { width: parent.width; wrapMode: Text.WordWrap; level: Label.Secondary; font.pixelSize: Theme.fsSm; text: win.status; visible: text !== "" }
            Button { visible: Shot.savedPath !== ""; text: qsTr("Ouvrir le dossier"); variant: Button.Ghost; onClicked: Shot.openFolder() }
            Label {
                width: parent.width; wrapMode: Text.WordWrap; level: Label.Tertiary; font.pixelSize: Theme.fsXs
                text: qsTr("%1 × %2 pixels").arg(Shot.imageWidth).arg(Shot.imageHeight)
            }
        }
    }
}
