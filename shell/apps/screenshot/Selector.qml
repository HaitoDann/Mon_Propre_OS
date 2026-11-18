import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.Screenshot

// Écran figé : on y trace une zone (ou on choisit l'écran entier). Une fenêtre par écran.
Window {
    id: win
    required property var modelData
    property var controller
    readonly property string name: modelData.name
    readonly property bool active: controller.activeScreen === name
    readonly property var sel: controller.selection && controller.selection.screen === name ? controller.selection : null
    readonly property real pixelRatio: Shot.screens.length ? frozen.implicitWidth / Math.max(1, width) : 1

    screen: { const all = Qt.application.screens; for (let i = 0; i < all.length; ++i) if (all[i].name === win.name) return all[i]; return null }
    x: modelData.x; y: modelData.y
    width: modelData.width; height: modelData.height
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    readonly property bool shown: controller.selecting && !controller.hidden
    onShownChanged: shown ? showFullScreen() : hide()
    Component.onCompleted: if (shown) showFullScreen()
    color: "black"
    title: qsTr("Capture d'écran")

    Image {
        id: frozen
        anchors.fill: parent
        source: "image://shot/screen/" + win.name
        cache: false
        smooth: true
    }

    // Voile autour de la sélection (ou sur tout l'écran).
    readonly property rect hole: sel ? Qt.rect(sel.x, sel.y, sel.width, sel.height)
                               : controller.tool === "screen" && hover.containsMouse ? Qt.rect(0, 0, width, height)
                               : Qt.rect(0, 0, 0, 0)
    Repeater {
        model: [
            Qt.rect(0, 0, win.width, win.hole.y),
            Qt.rect(0, win.hole.y + win.hole.height, win.width, win.height - win.hole.y - win.hole.height),
            Qt.rect(0, win.hole.y, win.hole.x, win.hole.height),
            Qt.rect(win.hole.x + win.hole.width, win.hole.y, win.width - win.hole.x - win.hole.width, win.hole.height)
        ]
        Rectangle { required property rect modelData; x: modelData.x; y: modelData.y; width: modelData.width; height: modelData.height; color: "#73000000" }
    }
    Rectangle {
        visible: win.hole.width > 0
        x: win.hole.x - 1; y: win.hole.y - 1; width: win.hole.width + 2; height: win.hole.height + 2
        color: "transparent"
        border.width: 2; border.color: Theme.accent
        Rectangle {
            visible: !!win.sel
            anchors { right: parent.right; bottom: parent.top; bottomMargin: 6 }
            width: size.implicitWidth + 12; height: 20; radius: Theme.radiusXs
            color: Theme.accent
            Label {
                id: size
                anchors.centerIn: parent
                color: Theme.accentForeground
                font.pixelSize: Theme.fsXs; font.weight: Font.DemiBold
                text: win.sel ? Math.round(win.sel.width * win.pixelRatio) + " × " + Math.round(win.sel.height * win.pixelRatio) : ""
            }
        }
    }

    // Tracé et déplacement de la zone ; clic sur l'écran en mode « Écran ».
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: controller.tool === "screen" ? Qt.PointingHandCursor : inside ? Qt.SizeAllCursor : Qt.CrossCursor
        property point origin
        property rect start
        property bool moving: false
        readonly property bool inside: !!win.sel && mouseX >= win.sel.x && mouseX <= win.sel.x + win.sel.width
                                       && mouseY >= win.sel.y && mouseY <= win.sel.y + win.sel.height
        onEntered: controller.activeScreen = win.name
        onPressed: (m) => {
            controller.activeScreen = win.name
            if (controller.tool === "screen") return
            origin = Qt.point(m.x, m.y)
            moving = inside
            start = win.sel ? Qt.rect(win.sel.x, win.sel.y, win.sel.width, win.sel.height) : Qt.rect(m.x, m.y, 0, 0)
        }
        onPositionChanged: (m) => {
            if (!pressed || controller.tool === "screen") return
            if (moving) {
                const nx = Math.max(0, Math.min(win.width - start.width, start.x + m.x - origin.x))
                const ny = Math.max(0, Math.min(win.height - start.height, start.y + m.y - origin.y))
                controller.selection = { screen: win.name, x: nx, y: ny, width: start.width, height: start.height }
            } else {
                const x = Math.max(0, Math.min(m.x, win.width)), y = Math.max(0, Math.min(m.y, win.height))
                controller.selection = { screen: win.name, x: Math.min(origin.x, x), y: Math.min(origin.y, y),
                                         width: Math.abs(x - origin.x), height: Math.abs(y - origin.y) }
            }
        }
        onReleased: {
            if (controller.selection && (controller.selection.width < 4 || controller.selection.height < 4)) controller.selection = null
        }
        onClicked: if (controller.tool === "screen") controller.take(win.name)
        onDoubleClicked: if (inside) controller.take()
    }

    // Aide en haut tant qu'aucune zone n'est tracée.
    Rectangle {
        visible: win.active && !win.sel && controller.tool === "zone"
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 48 }
        width: hint.implicitWidth + Theme.space5 * 2; height: 36; radius: 18
        color: Theme.surfaceGlassStrong
        border.width: 1; border.color: Theme.border
        Label { id: hint; anchors.centerIn: parent; text: qsTr("Faites glisser pour choisir une zone · Entrée pour capturer · Échap pour annuler") }
    }

    // ---------- Barre d'outils ----------
    Rectangle {
        id: toolbar
        visible: win.active
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 56 }
        width: bar.implicitWidth + 12; height: 46
        radius: Theme.radiusLg
        color: Theme.surfaceGlassStrong
        border.width: 1; border.color: Theme.border
        Row {
            id: bar
            anchors.centerIn: parent
            spacing: 4
            Repeater {
                model: [
                    { id: "zone", text: qsTr("Zone") },
                    { id: "window", text: qsTr("Fenêtre") },
                    { id: "screen", text: qsTr("Écran") }
                ]
                ToolChip {
                    required property var modelData
                    text: modelData.text
                    checked: controller.tool === modelData.id
                    onClicked: modelData.id === "window" ? controller.takeWindow() : controller.tool = modelData.id
                }
            }
            Rectangle { width: 1; height: 24; color: Theme.border; anchors.verticalCenter: parent.verticalCenter }
            ToolChip {
                text: controller.delay ? qsTr("Retardateur : %1 s").arg(controller.delay) : qsTr("Retardateur")
                checked: controller.delay > 0
                onClicked: controller.cycleDelay()
            }
            Rectangle { width: 1; height: 24; color: Theme.border; anchors.verticalCenter: parent.verticalCenter }
            ToolChip {
                objectName: "captureButton"
                text: qsTr("Capturer")
                primary: true
                enabled: controller.tool === "screen" || !!controller.selection
                onClicked: controller.take(win.name)
            }
            IconButton { iconName: "close"; flat: true; toolTip: qsTr("Annuler"); anchors.verticalCenter: parent.verticalCenter; onClicked: controller.cancel() }
        }
        MouseArea { anchors.fill: parent; z: -1 }   // ne pas tracer de zone sous la barre
    }

    Shortcut { sequence: "Escape"; onActivated: controller.selection ? controller.selection = null : controller.cancel() }
    Shortcut { sequences: ["Return", "Enter"]; onActivated: controller.take(win.name) }
}
