import QtQuick
import Vinx.Theme

// Aperçu fenêtré du shell (développement, captures, sessions sans layer-shell).
Window {
    id: win
    width: 1280; height: 800
    visible: true
    title: "VinX Shell — aperçu"
    color: Theme.background

    property bool startLight: false
    property string startOpen: ""
    Component.onCompleted: if (startLight) Theme.dark = false

    // Fond d'écran « Graphite » (approximation sans filtre)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.dark ? "#1C1D21" : "#EDEDF0" }
            GradientStop { position: 1; color: Theme.dark ? "#0F1012" : "#DCDCE0" }
        }
    }

    TopBar { id: bar; anchors { left: parent.left; right: parent.right; top: parent.top } }
    Panels { anchors.fill: parent }

    // Ouverture d'un panneau au démarrage (--open), après la mise en page.
    Timer {
        interval: 150
        running: win.startOpen !== ""
        onTriggered: {
            const target = bar.findButton(win.startOpen)
            if (target) target.open()
        }
    }
}
