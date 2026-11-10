import QtQuick
import Vinx.Theme
import Vinx.System

// Fond d'écran (en session VinX, plasmashell ne le dessine plus).
Rectangle {
    id: bg
    property string source: Preferences.value("desktop/wallpaper",
        "/usr/share/wallpapers/VinX-Graphite/contents/images/3840x2160.png")
    gradient: Gradient {
        GradientStop { position: 0; color: Theme.dark ? "#1C1D21" : "#EDEDF0" }
        GradientStop { position: 1; color: Theme.dark ? "#0F1012" : "#DCDCE0" }
    }
    Image {
        anchors.fill: parent
        source: Session.fileExists(bg.source) ? "file://" + bg.source : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(bg.width, bg.height)
        visible: status === Image.Ready
    }
}
