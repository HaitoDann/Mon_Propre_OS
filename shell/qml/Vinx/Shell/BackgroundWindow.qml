import QtQuick

// Surface de fond d'écran (layer-shell « background », plein écran).
Window {
    color: "black"
    visible: false
    title: "vinx-background"
    Background { anchors.fill: parent }
}
