import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell
import Vinx.Viewer

// Visionneur d'images VinX (ADR 0038), proposition A « immersive » : l'image sur fond sombre,
// barre flottante et miniatures qui s'effacent quand la souris ne bouge plus.
Window {
    id: win
    width: 1100; height: 760
    minimumWidth: 560; minimumHeight: 400
    visible: true
    title: Viewer.current ? Viewer.info.name : qsTr("Images")
    color: "#0E0F0F"
    AppearanceSync {}

    property string startMode: ""          // « edit » : ouvrir directement en mode Modifier
    property bool infoOpen: false
    property bool editing: false
    property bool slideshow: false
    property int viewTurns: 0               // rotation affichée, pas encore enregistrée
    property bool controlsShown: true
    property string toast: ""
    readonly property bool hasImage: Viewer.current !== ""

    function n(v, d) { return Number(v).toLocaleString(Qt.locale(), "f", d) }
    function bytes(v) { return v >= 1048576 ? qsTr("%1 Mo").arg(n(v / 1048576, 1)) : qsTr("%1 ko").arg(n(v / 1024, 0)) }
    function say(text) { toast = text; toastTimer.restart() }
    function poke() { controlsShown = true; idle.restart() }
    function edit() {
        if (!hasImage || Viewer.animated) return
        if (viewTurns) { Viewer.saveRotation(viewTurns); viewTurns = 0 }
        if (Viewer.beginEdit()) { editing = true; slideshow = false }
    }
    function remove() {
        const name = Viewer.info.name
        if (Viewer.trash()) say(qsTr("« %1 » mise à la corbeille.").arg(name))
    }
    function toggleFullScreen() { visibility === Window.FullScreen ? showNormal() : showFullScreen() }

    Component.onCompleted: if (startMode === "edit") Qt.callLater(edit)
    Connections {
        target: Viewer
        function onCurrentChanged() { win.viewTurns = 0; stage.fit() }
        function onFailed(message) { win.say(message) }
    }
    Timer { id: idle; interval: 2500; onTriggered: if (!toolbarHover.hovered && !shareMenu.open && !win.editing) win.controlsShown = false }
    Timer { id: toastTimer; interval: 3500; onTriggered: win.toast = "" }
    Timer { interval: 4000; running: win.slideshow; repeat: true; onTriggered: Viewer.next() }

    // ---------- Raccourcis ----------
    Shortcut { sequences: ["Right", "Space", "PgDown"]; enabled: !win.editing; onActivated: Viewer.next() }
    Shortcut { sequences: ["Left", "Backspace", "PgUp"]; enabled: !win.editing; onActivated: Viewer.previous() }
    Shortcut { sequence: "Home"; enabled: !win.editing; onActivated: Viewer.index = 0 }
    Shortcut { sequence: "End"; enabled: !win.editing; onActivated: Viewer.index = Viewer.files.length - 1 }
    Shortcut { sequences: ["+", "="]; enabled: !win.editing; onActivated: stage.zoomBy(1.25) }
    Shortcut { sequence: "-"; enabled: !win.editing; onActivated: stage.zoomBy(0.8) }
    Shortcut { sequence: "0"; enabled: !win.editing; onActivated: stage.fit() }
    Shortcut { sequence: "1"; enabled: !win.editing; onActivated: stage.actualSize() }
    Shortcut { sequence: "R"; enabled: !win.editing && win.hasImage; onActivated: win.viewTurns = (win.viewTurns + 1) % 4 }
    Shortcut { sequence: "Shift+R"; enabled: !win.editing && win.hasImage; onActivated: win.viewTurns = (win.viewTurns + 3) % 4 }
    Shortcut { sequence: "I"; enabled: !win.editing; onActivated: win.infoOpen = !win.infoOpen }
    Shortcut { sequence: "E"; enabled: !win.editing; onActivated: win.edit() }
    Shortcut { sequences: ["F", "F11"]; enabled: !win.editing; onActivated: win.toggleFullScreen() }
    Shortcut { sequence: "Delete"; enabled: !win.editing && win.hasImage; onActivated: win.remove() }
    Shortcut { sequences: [StandardKey.Copy]; enabled: !win.editing && win.hasImage; onActivated: { Viewer.copyImage(); win.say(qsTr("Image copiée.")) } }
    Shortcut {
        sequence: "Escape"
        enabled: !win.editing
        onActivated: {
            if (shareMenu.open) shareMenu.close()
            else if (win.slideshow) { win.slideshow = false; win.showNormal() }
            else if (win.visibility === Window.FullScreen) win.showNormal()
            else if (win.infoOpen) win.infoOpen = false
            else win.close()
        }
    }

    // ---------- Image ----------
    Stage {
        id: stage
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: info.left }
        turns: win.viewTurns
        onActivity: win.poke()
    }

    Label {
        anchors.centerIn: stage
        visible: !win.hasImage
        color: "#A3A6A3"
        text: qsTr("Aucune image à afficher.")
    }

    // Titre et position dans le dossier.
    Rectangle {
        anchors { left: stage.left; right: stage.right; top: parent.top }
        height: 56
        opacity: win.controlsShown && !win.slideshow ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }
        gradient: Gradient {
            GradientStop { position: 0; color: "#B0000000" }
            GradientStop { position: 1; color: "#00000000" }
        }
        Label {
            anchors { left: parent.left; leftMargin: Theme.space4; top: parent.top; topMargin: Theme.space3 }
            color: "#C8C8C6"
            font.pixelSize: Theme.fsSm
            text: "‹ " + (Viewer.info.folderName || "")
            visible: win.hasImage
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Viewer.openFolder() }
        }
        Label {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.space3 }
            width: Math.min(implicitWidth, parent.width - 240)
            elide: Text.ElideMiddle
            color: "#FFFFFF"
            font.weight: Font.DemiBold
            visible: win.hasImage
            text: Viewer.info.name + "  ·  " + (Viewer.index + 1) + " / " + Viewer.files.length
        }
    }

    // Flèches précédente / suivante.
    Repeater {
        model: win.hasImage && Viewer.files.length > 1 ? [-1, 1] : []
        Rectangle {
            required property int modelData
            x: modelData < 0 ? stage.x + Theme.space4 : stage.x + stage.width - width - Theme.space4
            anchors.verticalCenter: stage.verticalCenter
            width: 44; height: 44; radius: 22
            color: arrowMouse.containsMouse ? "#40FFFFFF" : "#26FFFFFF"
            opacity: win.controlsShown && !win.slideshow ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }
            Icon { anchors.centerIn: parent; width: 18; height: 18; name: parent.modelData < 0 ? "chevron-l" : "chevron-r"; color: "white" }
            MouseArea { id: arrowMouse; anchors.fill: parent; hoverEnabled: true; onClicked: parent.modelData < 0 ? Viewer.previous() : Viewer.next() }
            Accessible.role: Accessible.Button
            Accessible.name: modelData < 0 ? qsTr("Image précédente") : qsTr("Image suivante")
        }
    }

    // Rotation affichée mais pas encore écrite dans le fichier.
    Rectangle {
        visible: win.viewTurns !== 0 && !win.editing
        anchors { horizontalCenter: stage.horizontalCenter; top: parent.top; topMargin: 64 }
        width: rotRow.implicitWidth + Theme.space3 * 2; height: 44; radius: Theme.radiusLg
        color: "#E61E2120"; border.width: 1; border.color: "#1AFFFFFF"
        Row {
            id: rotRow
            anchors.centerIn: parent
            spacing: Theme.space2
            Label { anchors.verticalCenter: parent.verticalCenter; color: "#ECECEA"; text: qsTr("Rotation non enregistrée") }
            DarkChip { text: qsTr("Annuler"); onClicked: win.viewTurns = 0 }
            DarkChip {
                text: qsTr("Enregistrer"); primary: true
                onClicked: { if (Viewer.saveRotation(win.viewTurns)) win.say(qsTr("Rotation enregistrée.")); win.viewTurns = 0 }
            }
        }
    }

    // ---------- Barre flottante ----------
    Rectangle {
        id: toolbar
        anchors { horizontalCenter: stage.horizontalCenter; bottom: strip.top; bottomMargin: Theme.space3 }
        width: bar.implicitWidth + 10; height: 44
        radius: Theme.radiusLg
        color: "#E61E2120"
        border.width: 1; border.color: "#1AFFFFFF"
        opacity: win.controlsShown && win.hasImage && !win.slideshow ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }
        HoverHandler { id: toolbarHover }
        Row {
            id: bar
            anchors.centerIn: parent
            spacing: 2
            DarkChip { text: "−"; toolTip: qsTr("Réduire"); onClicked: stage.zoomBy(0.8) }
            DarkChip { text: stage.fitted ? qsTr("Ajuster") : qsTr("%1 %").arg(Math.round(stage.zoomPercent)); checked: true; onClicked: stage.fitted ? stage.actualSize() : stage.fit() }
            DarkChip { text: "+"; toolTip: qsTr("Agrandir"); onClicked: stage.zoomBy(1.25) }
            Rectangle { width: 1; height: 20; color: "#26FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
            DarkChip { text: "⟲  " + qsTr("Pivoter"); onClicked: win.viewTurns = (win.viewTurns + 3) % 4 }
            DarkChip { text: "✎  " + qsTr("Modifier"); enabled: !Viewer.animated; onClicked: win.edit() }
            DarkChip { text: "ⓘ  " + qsTr("Infos"); checked: win.infoOpen; onClicked: win.infoOpen = !win.infoOpen }
            Rectangle { width: 1; height: 20; color: "#26FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
            DarkChip { text: qsTr("Diaporama"); onClicked: { win.slideshow = true; win.showFullScreen() } }
            DarkChip { id: shareButton; text: qsTr("Partager"); primary: true; onClicked: shareMenu.show(shareButton) }
        }
    }

    // ---------- Miniatures ----------
    Rectangle {
        id: strip
        anchors { left: stage.left; right: stage.right; bottom: parent.bottom }
        height: win.controlsShown && Viewer.files.length > 1 && !win.slideshow ? 66 : 0
        visible: height > 0
        color: "#0B0C0C"
        Behavior on height { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }
        ListView {
            id: thumbs
            anchors { fill: parent; margins: 8 }
            orientation: ListView.Horizontal
            spacing: 8
            model: Viewer.files
            currentIndex: Viewer.index
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: width / 2 - 30
            preferredHighlightEnd: width / 2 + 30
            highlightMoveDuration: Theme.durNormal
            clip: true
            delegate: Item {
                id: thumb
                required property int index
                required property string modelData
                width: 60; height: 46
                Image {
                    anchors.fill: parent
                    source: "file://" + thumb.modelData
                    sourceSize: Qt.size(120, 92)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    opacity: thumb.index === Viewer.index ? 1 : 0.55
                }
                Rectangle {
                    anchors { fill: parent; margins: -3 }
                    radius: 7
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.accent
                    visible: thumb.index === Viewer.index
                }
                MouseArea { anchors.fill: parent; onClicked: Viewer.index = thumb.index }
            }
        }
    }

    // ---------- Infos ----------
    InfoPanel {
        id: info
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: win.infoOpen && win.hasImage && !win.slideshow ? 290 : 0
        clip: true
        Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }
        onCloseRequested: win.infoOpen = false
        onWallpaper: { Preferences.setValue("desktop/wallpaper", Viewer.current); win.say(qsTr("Fond d'écran changé.")) }
    }

    // ---------- Partager ----------
    Item {
        anchors.fill: parent
        Menu {
            id: shareMenu
            edge: Popover.Above
            align: Popover.End
            model: [
                { text: qsTr("Copier l'image"), shortcut: qsTr("Ctrl+C") },
                { text: qsTr("Envoyer par e-mail…") },
                { separator: true },
                { text: qsTr("Utiliser comme fond d'écran") },
                { text: qsTr("Ouvrir le dossier") },
                { text: qsTr("Ouvrir avec…") },
                { separator: true },
                { text: qsTr("Mettre à la corbeille"), shortcut: qsTr("Suppr") }
            ]
            onTriggered: (index) => {
                switch (index) {
                case 0: Viewer.copyImage(); win.say(qsTr("Image copiée.")); break
                case 1: if (!Viewer.email()) win.say(qsTr("Aucune messagerie n'est configurée.")); break
                case 3: Preferences.setValue("desktop/wallpaper", Viewer.current); win.say(qsTr("Fond d'écran changé.")); break
                case 4: Viewer.openFolder(); break
                case 5: Viewer.openWith(); break
                case 7: win.remove(); break
                }
            }
        }
    }

    // ---------- Message ----------
    Rectangle {
        visible: win.toast !== ""
        anchors { horizontalCenter: stage.horizontalCenter; top: parent.top; topMargin: 64 }
        width: toastLabel.implicitWidth + Theme.space5 * 2; height: 38; radius: 19
        color: "#E61E2120"; border.width: 1; border.color: "#1AFFFFFF"
        Label { id: toastLabel; anchors.centerIn: parent; color: "#ECECEA"; text: win.toast }
    }

    // ---------- Mode Modifier ----------
    Loader {
        anchors.fill: parent
        active: win.editing
        sourceComponent: EditView {
            onFinished: (saved) => {
                win.editing = false
                if (saved) win.say(saved)
                win.poke()
            }
        }
    }

    // Mouvements de la souris : barres visibles, puis masquées après 2,5 s d'immobilité.
    HoverHandler { onPointChanged: win.poke() }
}
