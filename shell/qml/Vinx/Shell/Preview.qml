import QtQuick
import Vinx.Theme
import Vinx.System

// Aperçu fenêtré du shell (développement, captures, sessions sans layer-shell).
Window {
    id: win
    width: 1280; height: 800
    visible: true
    title: "VinX Shell — aperçu"
    color: Theme.background

    property bool startLight: false
    property string startOpen: ""
    // Aperçu : fenêtres simulées au démarrage (--demo).
    property bool demo: false
    Component.onCompleted: {
        if (startLight) Theme.dark = false
        if (demo && Tasks.backend.openApp) {
            Tasks.backend.launchApps = false
            Tasks.backend.activate(1)          // Firefox
            Tasks.backend.activate(2)          // Documents
            Tasks.backend.openApp("org.kde.konsole", "Terminal")
            Tasks.backend.activate(2)
            Notifications.notify("Thunderbird", qsTr("Nouveau message"), qsTr("Réunion d'équipe : l'ordre du jour est disponible."), "thunderbird")
            Notifications.notify("Store", qsTr("Installation terminée"), qsTr("Le pack Graphisme est prêt."), "")
        }
    }

    Background { anchors.fill: parent }
    TopBar { id: bar; anchors { left: parent.left; right: parent.right; top: parent.top } }
    Dock { id: dock; anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 160 }
    Toasts { anchors { right: parent.right; top: bar.bottom; margins: Theme.space2 } }
    Panels { anchors.fill: parent }

    // Ouverture d'un panneau au démarrage (--open), après la mise en page.
    Timer {
        interval: 150
        running: win.startOpen !== ""
        onTriggered: {
            if (win.startOpen === "dock") {
                const it = dock.itemAt(1)
                if (it) ShellState.openDockMenu(1, it.appName, it.running, true, dock.rectOf(it))
                return
            }
            const target = bar.findButton(win.startOpen)
            if (target) target.open()
        }
    }
}
