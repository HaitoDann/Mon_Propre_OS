import QtQuick
import Vinx.Theme
import Vinx.System
import Vinx.Controls

// Fond d'écran (en session VinX, plasmashell ne le dessine plus).
Rectangle {
    id: bg
    readonly property string source: { Preferences.revision; return Preferences.value("desktop/wallpaper",
        "/usr/share/wallpapers/VinX-Logo/contents/images/3840x2160.png") }
    // Widgets et menu contextuel du bureau.
    property bool interactive: true
    gradient: Gradient {
        GradientStop { position: 0; color: Theme.dark ? "#1C1D21" : "#EDEDF0" }
        GradientStop { position: 1; color: Theme.dark ? "#0F1012" : "#DCDCE0" }
    }
    // « VinX Logo » (clair : suit le thème ; sombre : toujours sombre) est dessiné en direct à la couleur d'accent.
    readonly property var logoMatch: /\/VinX-Logo(-Sombre)?\//.exec(source)
    LogoWallpaper {
        anchors.fill: parent
        visible: bg.logoMatch !== null
        dark: bg.logoMatch !== null && bg.logoMatch[1] !== undefined ? true : Theme.dark
    }
    Image {
        anchors.fill: parent
        visible: status === Image.Ready && bg.logoMatch === null
        source: bg.logoMatch === null && Session.fileExists(bg.source) ? "file://" + bg.source : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(bg.width, bg.height)
    }

    MouseArea {
        anchors.fill: parent
        enabled: bg.interactive
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: (m) => {
            if (m.button === Qt.RightButton)
                ShellState.openDesktopMenu(Qt.rect(m.x, m.y, 1, 1), Window.window && Window.window.screen ? Window.window.screen.name : "")
            else ShellState.close()
        }
    }
    // Dock à gauche : les widgets se décalent pour ne pas passer dessous.
    DesktopWidgets {
        anchors.fill: parent
        anchors.leftMargin: (Preferences.revision, String(Preferences.value("dock/position", "bottom")) === "left") ? Theme.dockIcon + Theme.space6 * 2 : 0
        visible: bg.interactive
    }
}
