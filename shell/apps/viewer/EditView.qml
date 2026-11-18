import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.Viewer

// Mode Modifier : recadrer, pivoter, lumière, annoter (outils de la capture d'écran),
// réduire pour un mail. Enregistre une copie par défaut ; remplacer l'original est un choix à part.
Rectangle {
    id: view
    color: Theme.surfaceWindow
    signal finished(string message)

    property string tool: "crop"
    property real ratio: 0                 // 0 = libre ; largeur / hauteur sinon
    property color ink: colors[0]
    readonly property var colors: ["#FF5F57", "#FEBC2E", "#10DD8C", "#2E9BFF", "#141414"]
    property bool confirmReplace: false
    readonly property bool annotating: ["arrow", "frame", "highlight", "blur", "text"].includes(tool)

    // Cadre de recadrage en fractions de l'image pivotée.
    property rect cr: Viewer.crop.width > 0 ? Viewer.crop : Qt.rect(0, 0, 1, 1)
    Connections { target: Viewer; function onEditChanged() { if (!frameDrag.active) view.cr = Viewer.crop.width > 0 ? Viewer.crop : Qt.rect(0, 0, 1, 1) } }

    function setRatio(r) {
        ratio = r
        tool = "crop"
        if (r <= 0) return
        const w = Viewer.baseSize.width, h = Viewer.baseSize.height
        // Plus grand cadre centré à ce format.
        let fw = 1, fh = (w / r) / h
        if (fh > 1) { fh = 1; fw = (h * r) / w }
        Viewer.crop = Qt.rect((1 - fw) / 2, (1 - fh) / 2, fw, fh)
    }
    function leave(message) { view.finished(message) }

    Shortcut { sequences: [StandardKey.Undo]; enabled: !textEntry.visible; onActivated: Viewer.undo() }
    Shortcut { sequence: "Escape"; enabled: !textEntry.visible; onActivated: view.leave("") }
    Shortcut { sequences: [StandardKey.Save]; onActivated: { const p = Viewer.saveCopy(); if (p) view.leave(qsTr("Copie enregistrée : %1").arg(p.split("/").pop())) } }

    // ---------- Aperçu ----------
    Rectangle {
        id: area
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: side.left }
        color: "#151716"

        Image {
            id: picture
            anchors { fill: parent; margins: Theme.space6 }
            fillMode: Image.PreserveAspectFit
            cache: false
            smooth: true
            mipmap: true
            source: Viewer.revision >= 0 ? (view.tool === "crop" ? "image://photo/base/" : "image://photo/edited/") + Viewer.revision : ""
            readonly property real offX: (width - paintedWidth) / 2
            readonly property real offY: (height - paintedHeight) / 2
            readonly property real scale: paintedWidth > 0 ? implicitWidth / paintedWidth : 1
            function toImage(p) { return Qt.point((p.x - offX) * scale, (p.y - offY) * scale) }
        }

        // Recadrage : voile, cadre, tiers, poignées aux coins.
        Item {
            id: cropLayer
            visible: view.tool === "crop"
            x: picture.x + picture.offX; y: picture.y + picture.offY
            width: picture.paintedWidth; height: picture.paintedHeight
            readonly property rect px: Qt.rect(view.cr.x * width, view.cr.y * height, view.cr.width * width, view.cr.height * height)
            Repeater {
                model: [
                    Qt.rect(0, 0, cropLayer.width, cropLayer.px.y),
                    Qt.rect(0, cropLayer.px.y + cropLayer.px.height, cropLayer.width, cropLayer.height - cropLayer.px.y - cropLayer.px.height),
                    Qt.rect(0, cropLayer.px.y, cropLayer.px.x, cropLayer.px.height),
                    Qt.rect(cropLayer.px.x + cropLayer.px.width, cropLayer.px.y, cropLayer.width - cropLayer.px.x - cropLayer.px.width, cropLayer.px.height)
                ]
                Rectangle { required property rect modelData; x: modelData.x; y: modelData.y; width: modelData.width; height: modelData.height; color: "#99000000" }
            }
            Rectangle {
                id: frame
                x: cropLayer.px.x; y: cropLayer.px.y; width: cropLayer.px.width; height: cropLayer.px.height
                color: "transparent"
                border.width: 2; border.color: "white"
                Repeater {
                    model: [1 / 3, 2 / 3]
                    Item {
                        required property real modelData
                        anchors.fill: parent
                        Rectangle { x: frame.width * parent.modelData; width: 1; height: frame.height; color: "#66FFFFFF" }
                        Rectangle { y: frame.height * parent.modelData; height: 1; width: frame.width; color: "#66FFFFFF" }
                    }
                }
                // Déplacer le cadre.
                MouseArea {
                    id: frameDrag
                    property bool active: pressed
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    property point start
                    property rect from
                    onPressed: (m) => { start = mapToItem(cropLayer, m.x, m.y); from = view.cr }
                    onPositionChanged: (m) => {
                        const p = mapToItem(cropLayer, m.x, m.y)
                        const dx = (p.x - start.x) / cropLayer.width, dy = (p.y - start.y) / cropLayer.height
                        view.cr = Qt.rect(Math.max(0, Math.min(1 - from.width, from.x + dx)), Math.max(0, Math.min(1 - from.height, from.y + dy)), from.width, from.height)
                    }
                    onReleased: Viewer.crop = view.cr
                }
                // Poignées : coin (sx, sy) = −1 gauche/haut, 1 droite/bas.
                Repeater {
                    model: [[-1, -1], [1, -1], [-1, 1], [1, 1]]
                    Rectangle {
                        id: handle
                        required property var modelData
                        width: 18; height: 18; radius: 9
                        color: "white"
                        border.width: 2; border.color: Theme.accent
                        x: (modelData[0] < 0 ? 0 : frame.width) - width / 2
                        y: (modelData[1] < 0 ? 0 : frame.height) - height / 2
                        MouseArea {
                            anchors { fill: parent; margins: -8 }
                            cursorShape: handle.modelData[0] === handle.modelData[1] ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                            property rect from
                            onPressed: from = view.cr
                            onPositionChanged: (m) => {
                                const p = mapToItem(cropLayer, m.x, m.y)
                                const fx = Math.max(0, Math.min(1, p.x / cropLayer.width)), fy = Math.max(0, Math.min(1, p.y / cropLayer.height))
                                // Coin opposé fixe.
                                const ox = handle.modelData[0] < 0 ? from.x + from.width : from.x
                                const oy = handle.modelData[1] < 0 ? from.y + from.height : from.y
                                let w = Math.max(0.03, Math.abs(fx - ox)), h = Math.max(0.03, Math.abs(fy - oy))
                                if (view.ratio > 0) {   // format imposé : la hauteur suit la largeur
                                    h = w * cropLayer.width / view.ratio / cropLayer.height
                                    if (h > (handle.modelData[1] < 0 ? oy : 1 - oy)) { h = handle.modelData[1] < 0 ? oy : 1 - oy; w = h * cropLayer.height * view.ratio / cropLayer.width }
                                }
                                const x = handle.modelData[0] < 0 ? Math.max(0, ox - w) : ox
                                const y = handle.modelData[1] < 0 ? Math.max(0, oy - h) : oy
                                view.cr = Qt.rect(x, y, Math.min(w, 1 - x), Math.min(h, 1 - y))
                            }
                            onReleased: Viewer.crop = view.cr
                        }
                    }
                }
            }
        }

        // Annotations : aperçu du tracé en cours, rendu définitif par le C++.
        Canvas {
            id: sketch
            anchors.fill: picture
            visible: view.annotating
            property point a
            property point b
            property bool drawing: false
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                if (!drawing) return
                const x = Math.min(a.x, b.x), y = Math.min(a.y, b.y), w = Math.abs(b.x - a.x), h = Math.abs(b.y - a.y)
                ctx.lineWidth = 3
                ctx.strokeStyle = view.ink
                if (view.tool === "arrow") { ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke() }
                else if (view.tool === "frame") ctx.strokeRect(x, y, w, h)
                else if (view.tool === "highlight") { ctx.fillStyle = Qt.rgba(view.ink.r, view.ink.g, view.ink.b, 0.35); ctx.fillRect(x, y, w, h) }
                else if (view.tool === "blur") { ctx.fillStyle = "#80808080"; ctx.fillRect(x, y, w, h) }
            }
        }
        MouseArea {
            anchors.fill: picture
            enabled: view.annotating
            cursorShape: view.tool === "text" ? Qt.IBeamCursor : Qt.CrossCursor
            onPressed: (m) => {
                if (view.tool === "text") { textEntry.open(m.x, m.y); return }
                sketch.a = Qt.point(m.x, m.y); sketch.b = sketch.a; sketch.drawing = true; sketch.requestPaint()
            }
            onPositionChanged: (m) => { if (sketch.drawing) { sketch.b = Qt.point(m.x, m.y); sketch.requestPaint() } }
            onReleased: {
                if (!sketch.drawing) return
                sketch.drawing = false
                sketch.requestPaint()
                const p1 = picture.toImage(sketch.a), p2 = picture.toImage(sketch.b)
                if (Math.abs(p2.x - p1.x) + Math.abs(p2.y - p1.y) < 6) return
                Viewer.addShape({ kind: view.tool, x1: p1.x, y1: p1.y, x2: p2.x, y2: p2.y, color: view.ink.toString() })
            }
        }
        Rectangle {
            id: textEntry
            visible: false
            property point at
            function open(x, y) { at = Qt.point(x, y); field.text = ""; visible = true; field.forceActiveFocus() }
            function commit() {
                if (field.text.trim()) {
                    const p = picture.toImage(Qt.point(at.x, at.y + 22))
                    Viewer.addShape({ kind: "text", x1: p.x, y1: p.y, x2: p.x, y2: p.y, color: view.ink.toString(), text: field.text })
                }
                visible = false
            }
            x: picture.x + at.x; y: picture.y + at.y
            width: Math.max(160, field.contentWidth + 16); height: 30
            radius: Theme.radiusXs
            color: Theme.surfaceWindow
            border.width: 2; border.color: view.ink
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

    // ---------- Réglages ----------
    Rectangle {
        id: side
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: 290
        color: Theme.surfaceWindow
        Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.border }
        Flickable {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: actions.top; margins: Theme.space4 }
            contentHeight: settings.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: settings
                width: parent.width
                spacing: Theme.space2

                Label { text: Viewer.info.name || ""; level: Label.Tertiary; font.pixelSize: Theme.fsSm; width: parent.width; elide: Text.ElideMiddle }

                SectionTitle { text: qsTr("Recadrer") }
                Flow {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: [
                            { text: qsTr("Libre"), ratio: 0 },
                            { text: qsTr("Original"), ratio: Viewer.baseSize.height > 0 ? Viewer.baseSize.width / Viewer.baseSize.height : 0 },
                            { text: qsTr("Carré"), ratio: 1 },
                            { text: "16:9", ratio: 16 / 9 },
                            { text: "4:3", ratio: 4 / 3 }
                        ]
                        Pill {
                            required property var modelData
                            required property int index
                            text: modelData.text
                            checked: view.tool === "crop" && (index === 0 ? view.ratio === 0 : Math.abs(view.ratio - modelData.ratio) < 0.001)
                            onClicked: view.setRatio(modelData.ratio)
                        }
                    }
                }

                SectionTitle { text: qsTr("Pivoter") }
                Flow {
                    width: parent.width; spacing: 6
                    Pill { text: "⟲ 90°"; onClicked: Viewer.rotate(-1) }
                    Pill { text: "⟳ 90°"; onClicked: Viewer.rotate(1) }
                    Pill { text: "↔ " + qsTr("Miroir"); checked: Viewer.mirror; onClicked: Viewer.flip() }
                }

                SectionTitle { text: qsTr("Lumière") }
                Label { text: qsTr("Luminosité"); level: Label.Secondary; font.pixelSize: Theme.fsSm }
                Slider { width: parent.width; from: -100; to: 100; stepSize: 5; value: Viewer.brightness; onMoved: (v) => Viewer.brightness = Math.round(v) }
                Label { text: qsTr("Contraste"); level: Label.Secondary; font.pixelSize: Theme.fsSm }
                Slider { width: parent.width; from: -100; to: 100; stepSize: 5; value: Viewer.contrast; onMoved: (v) => Viewer.contrast = Math.round(v) }

                SectionTitle { text: qsTr("Annoter") }
                Flow {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: [
                            { id: "arrow", text: "➚ " + qsTr("Flèche") }, { id: "frame", text: "▭ " + qsTr("Cadre") },
                            { id: "highlight", text: "▬ " + qsTr("Surligner") }, { id: "blur", text: "▦ " + qsTr("Flouter") },
                            { id: "text", text: "T " + qsTr("Texte") }
                        ]
                        Pill {
                            required property var modelData
                            text: modelData.text
                            checked: view.tool === modelData.id
                            onClicked: view.tool = view.tool === modelData.id ? "" : modelData.id
                        }
                    }
                }
                Row {
                    spacing: 8
                    topPadding: 4
                    visible: view.annotating
                    Repeater {
                        model: view.colors
                        Rectangle {
                            required property string modelData
                            width: 22; height: 22; radius: 11
                            color: modelData
                            Rectangle { anchors.centerIn: parent; width: 30; height: 30; radius: 15; color: "transparent"; border.width: 2; border.color: Theme.text; visible: Qt.colorEqual(view.ink, parent.modelData) }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: view.ink = parent.modelData }
                        }
                    }
                }

                SectionTitle { text: qsTr("Taille") }
                Pill { text: qsTr("Réduire pour un mail (1600 px)"); checked: Viewer.forMail; onClicked: Viewer.forMail = !Viewer.forMail }
                Label {
                    level: Label.Tertiary; font.pixelSize: Theme.fsSm
                    text: qsTr("Résultat : %1 × %2 pixels").arg(Viewer.editedSize.width).arg(Viewer.editedSize.height)
                }
                Row {
                    spacing: Theme.space2
                    topPadding: Theme.space2
                    Button { text: qsTr("Annuler"); variant: Button.Ghost; enabled: Viewer.canUndo; onClicked: Viewer.undo() }
                    Button { text: qsTr("Tout réinitialiser"); variant: Button.Ghost; enabled: Viewer.modified; onClicked: Viewer.resetEdits() }
                }
            }
        }
        Column {
            id: actions
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.space4 }
            spacing: Theme.space2
            Button {
                objectName: "saveCopy"
                width: parent.width; text: qsTr("Enregistrer une copie"); variant: Button.Primary; enabled: Viewer.modified
                onClicked: { const p = Viewer.saveCopy(); if (p) view.leave(qsTr("Copie enregistrée : %1").arg(p.split("/").pop())) }
            }
            Button {
                width: parent.width
                enabled: Viewer.modified
                text: view.confirmReplace ? qsTr("Confirmer : remplacer l'original") : qsTr("Remplacer l'original")
                onClicked: {
                    if (!view.confirmReplace) { view.confirmReplace = true; confirmTimer.restart(); return }
                    if (Viewer.replaceOriginal()) view.leave(qsTr("Image enregistrée."))
                }
                Timer { id: confirmTimer; interval: 4000; onTriggered: view.confirmReplace = false }
            }
            Button { width: parent.width; text: qsTr("Fermer sans enregistrer"); variant: Button.Ghost; onClicked: view.leave("") }
        }
    }

    component SectionTitle: Label {
        topPadding: Theme.space3
        font.weight: Font.DemiBold
    }
    component Pill: Rectangle {
        id: pill
        property string text
        property bool checked: false
        signal clicked()
        width: pillLabel.implicitWidth + Theme.space3 * 2
        height: 30
        radius: 15
        color: checked ? Theme.accent : pillMouse.containsMouse ? Theme.surfaceHover : "transparent"
        border.width: checked ? 0 : 1
        border.color: Theme.border
        Label {
            id: pillLabel
            anchors.centerIn: parent
            text: pill.text
            font.pixelSize: Theme.fsSm
            font.weight: pill.checked ? Font.DemiBold : Font.Normal
            color: pill.checked ? Theme.accentForeground : Theme.text
        }
        MouseArea { id: pillMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
        Accessible.role: Accessible.Button
        Accessible.name: text
    }
}
