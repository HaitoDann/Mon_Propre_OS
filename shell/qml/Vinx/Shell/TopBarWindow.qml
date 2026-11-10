import QtQuick
import Vinx.Theme
import Vinx.System

// Fenêtre de la barre (surface layer-shell ancrée en haut, configurée par vinx-shell).
Window {
    width: Screen.width
    height: Theme.topbarHeight
    color: "transparent"
    visible: false   // affichée par le C++ après configuration layer-shell
    title: "vinx-topbar"
    // Une barre par écran ; seule celle de l'écran principal pilote les tâches de session.
    property bool isPrimary: true
    AppearanceSync {}
    // Les fenêtres des applications suivent l'apparence (palette KDE VinX claire / sombre).
    Connections {
        target: Theme
        enabled: isPrimary
        function onDarkChanged() { Session.launch("plasma-apply-colorscheme", [Theme.dark ? "VinXDark" : "VinXLight"]) }
    }
    TopBar { anchors.fill: parent }

    // Premier démarrage : assistant de bienvenue (une seule fois).
    Timer {
        interval: 2500
        running: isPrimary
        onTriggered: {
            const done = Preferences.value("welcome/done", false)
            if (done !== true && done !== "true") Session.launch("vinx-welcome")
        }
    }
}
