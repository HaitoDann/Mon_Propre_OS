import QtQuick
import Vinx.Theme
import Vinx.System

// Aperçu fenêtré du shell (développement, captures, sessions sans layer-shell).
Window {
    id: win
    width: 1280; height: 800
    visible: true
    title: "VinX Shell — aperçu"
    AppearanceSync { id: appearance }
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
            Tasks.backend.openApp("org.kde.konsole", "Terminal")
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
