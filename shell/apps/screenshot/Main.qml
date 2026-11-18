import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.Screenshot

// Capture d'écran VinX (ADR 0036). Trois façons d'arriver ici :
// - Méta+Maj+S : écrans figés, sélection d'une zone, d'une fenêtre ou d'un écran, puis annotation ;
// - Impr. écran (--full) : tout l'écran, copié et enregistré, bulle avec « Annoter » ;
// - --edit fichier : annoter une image existante.
// Toute capture est copiée aussitôt dans le presse-papiers.
QtObject {
    id: root
    default property list<QtObject> objects
    property string startMode: "select"
    property string tool: "zone"            // zone | screen
    property int delay: 0                    // secondes
    readonly property var delays: [0, 3, 5, 10]
    property bool selecting: startMode === "select"
    property bool hidden: false              // retardateur ou choix de fenêtre par KWin
    property bool editorOpen: startMode === "edit"
    property var selection: null             // { screen, x, y, width, height } en coordonnées logiques
    property string activeScreen: Shot.cursorScreen()
    property string pending: ""              // capture à faire dès que les écrans sont rafraîchis
    property string error: ""

    function cancel() {
        if (!editorOpen) Qt.quit()
        selecting = false
    }
    function cycleDelay() { delay = delays[(delays.indexOf(delay) + 1) % delays.length] }
    function take(screenName) {
        if (tool === "zone" && !selection) return
        const target = tool === "zone" ? "zone" : "screen:" + (screenName || activeScreen)
        if (delay > 0) { pending = target; hidden = true; delayTimer.start() }
        else run(target)
    }
    function takeWindow() {
        hidden = true
        windowTimer.interval = Math.max(250, delay * 1000)
        windowTimer.start()
    }
    function run(target) {
        if (target === "zone") Shot.takeArea(selection.screen, selection.x, selection.y, selection.width, selection.height)
        else Shot.takeScreen(target.slice(7))
    }

    property Timer delayTimer: Timer {
        interval: root.delay * 1000
        onTriggered: Shot.grabScreens()   // l'écran a changé pendant l'attente : nouvelle image
    }
    // Laisser le temps aux fenêtres de sélection de disparaître avant que KWin propose le choix.
    property Timer windowTimer: Timer { onTriggered: Shot.takeWindow() }
    property Timer quitTimer: Timer { interval: 10000; onTriggered: if (!root.editorOpen) Qt.quit() }

    property Connections shotEvents: Connections {
        target: Shot
        function onScreensReady() {
            if (root.pending) { const t = root.pending; root.pending = ""; root.run(t) }
        }
        function onCaptured() {
            root.selecting = false
            root.hidden = false
            if (root.startMode === "full") {
                if (Shot.save()) Shot.notifySaved()
                root.quitTimer.start()
            } else root.editorOpen = true
        }
        function onFailed(message) {
            root.hidden = false
            root.error = message
            if (root.startMode === "full") Qt.quit()
        }
        function onAnnotateRequested() { root.quitTimer.stop(); root.editorOpen = true }
    }

    property Instantiator selectors: Instantiator {
        model: root.startMode === "select" ? Shot.screens : []
        delegate: Selector { controller: root }
    }

    property Editor editor: Editor {
        visible: root.editorOpen
        onClosing: Qt.quit()
    }
}
