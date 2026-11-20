import QtQuick
import Vinx.Theme
import Vinx.System

// Aperçu fenêtré du shell (développement, captures, sessions sans layer-shell).
Window {
    id: win
    width: 1280; height: 800
    visible: true
    title: "VinX Shell — aperçu"
    AppearanceSync { id: appearance; spaces: true }
    color: Theme.background

    property bool startLight: false
    property string startOpen: ""
    // Aperçu : fenêtres simulées au démarrage (--demo).
    property bool demo: false
    Component.onCompleted: {
        if (startLight) Theme.dark = false   // aperçu uniquement (sans écrire les préférences)
        if (demo && Tasks.backend.openApp) {
            Tasks.backend.launchApps = false
            Tasks.backend.activate(1)          // Firefox
            Tasks.backend.activate(2)          // Documents
            Tasks.backend.openApp("org.vinx.terminal", "Terminal")
            Tasks.backend.activate(2)
            Tasks.backend.newInstance(2)       // Documents : deux fenêtres, dont une réduite
            Tasks.backend.minimizeWindow(2, 0)
            Tasks.backend.minimizeWindow(1, 0) // Firefox réduit
            Notifications.notifyFull("Thunderbird", qsTr("Nouveau message"), qsTr("Réunion d'équipe : l'ordre du jour est disponible."),
                                     ["default", qsTr("Ouvrir"), "reply", qsTr("Répondre"), "read", qsTr("Marquer comme lu")], {})
            Notifications.notify("Thunderbird", qsTr("Nouveau message"), qsTr("Facture de novembre"))
            Notifications.notify("Store", qsTr("Installation terminée"), qsTr("Le pack Graphisme est prêt."), "")
        }
    }

    Background { anchors.fill: parent }
    TopBar { id: bar; anchors { left: parent.left; right: parent.right; top: parent.top } }
    Dock { id: dock; anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: vertical ? bar.bottom : undefined } height: vertical ? undefined : 160 }
    Toasts { anchors { right: parent.right; top: bar.bottom; margins: Theme.space2 } }
    Panels { anchors.fill: parent }
    Osd { id: osd; anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 100 } }

    function findSpaces(item) {
        if (!item) return null
        if (typeof item.addSpace === "function") return item
        const kids = item.children || []
        for (let i = 0; i < kids.length; ++i) { const r = findSpaces(kids[i]); if (r) return r }
        return null
    }
    // Ouverture d'un panneau au démarrage (--open), après la mise en page.
    Timer {
        interval: 150
        running: win.startOpen !== ""
        onTriggered: {
            if (win.startOpen === "dock") {
                const it = dock.itemAt(1)
                if (it) ShellState.openDockMenu(1, it.appName, it.running, true, dock.rectOf(it), "")
                return
            }
            if (win.startOpen === "osd") { osd.show("volume", "volume", 64, ""); return }
            if (win.startOpen === "power") { ShellState.askPower("all"); return }
            if (win.startOpen.startsWith("spaces")) {     // espaces nommés (ADR 0044)
                const b = Tasks.backend
                if (win.demo && b) {
                    b.renameDesktop(0, "Travail"); b.renameDesktop(1, "Compta"); b.renameDesktop(2, "Maison")
                    if (win.startOpen.indexOf("color") >= 0) { ShellState.setSpaceColorAt(1, "corail"); ShellState.setSpaceColorAt(2, "lagon") }
                }
                if (win.startOpen === "spaces-color-switch") { b.activateDesktop(1); return }
                if (win.startOpen === "spaces-color-dark") { Preferences.setValue("appearance/dark", true); b.activateDesktop(2); return }
                if (win.startOpen === "spaces-switch") { b.activateDesktop(1); return }
                bar.findButton("spaces").open()
                if (win.startOpen === "spaces-edit" || win.startOpen === "spaces-color-edit")
                    Qt.callLater(() => { const p = findSpaces(win.contentItem); if (p) { p.editing = true; if (win.startOpen === "spaces-color-edit") p.paletteFor = 1 } })
                return
            }
            if (win.startOpen === "search") { ShellState.toggle("search", Qt.rect(0, 0, 0, 0)); return }
            if (win.startOpen === "clipboard") {      // historique d'exemple
                if (win.demo) {
                    for (const t of ["IBAN FR76 3000 6000 0112 3456 7890 189", "https://www.service-public.fr/particuliers",
                                     "Bonjour Claire,\nvoici le compte rendu de la réunion de mardi.", "Réunion d'équipe jeudi 14 h, salle B"])
                        Clipboard.copyText(t)
                    const first = Clipboard.items[0]
                    if (first) Clipboard.setPinned(first.id, true)
                }
                ShellState.toggle("clipboard", Qt.rect(0, 0, 0, 0))
                return
            }
            if (win.startOpen === "windows") {      // liste des fenêtres de Documents
                const it = dock.itemAt(2)
                if (it) ShellState.openWindowList(2, it.appName, dock.rectOf(it), "")
                return
            }
            const target = bar.findButton(win.startOpen)
            if (target) target.open()
        }
    }
}
