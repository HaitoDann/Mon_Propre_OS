import QtQuick
import Vinx.Theme
import Vinx.Controls

// Fond « VinX Logo » dessiné en direct (ADR 0021) : grille de points et logo à la couleur d'accent.
// Même composition que branding/wallpaper/vinx-logo-*.svg (espace de dessin 3840 × 2160, recadré
// pour remplir l'écran). Le changement d'accent se fait en fondu enchaîné.
Rectangle {
    id: root
    property bool dark: Theme.dark
    property color logoColor: Theme.logo

    readonly property real unit: Math.max(width / 3840, height / 2160)
    readonly property real originX: (width - 3840 * unit) / 2
    readonly property real originY: (height - 2160 * unit) / 2

    color: dark ? "#121413" : "#ECEBE6"
    Behavior on color { ColorAnimation { duration: Theme.durSlow } }

    Canvas {
        id: dots
        anchors.fill: parent
        readonly property color dotColor: root.dark ? "#2C302E" : "#D2D0C9"
        onDotColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = dotColor
            const step = 72 * root.unit, r = Math.max(1, 3 * root.unit)
            const x0 = root.originX + 6 * root.unit, y0 = root.originY + 6 * root.unit
            ctx.beginPath()
            for (let y = y0 - Math.ceil(y0 / step) * step; y < height + step; y += step)
                for (let x = x0 - Math.ceil(x0 / step) * step; x < width + step; x += step) {
                    ctx.moveTo(x + r, y)
                    ctx.arc(x, y, r, 0, 2 * Math.PI)
                }
            ctx.fill()
        }
    }

    Item {
        id: logo
        x: root.originX + 1680 * root.unit
        y: root.originY + 510 * root.unit
        width: 1024 * 1.8164 * root.unit
        height: 735 * 1.8164 * root.unit
        // Couleur précédente, qui s'efface au-dessus de la nouvelle.
        Icon { id: current; anchors.fill: parent; name: "vinx"; color: root.logoColor }
        Icon { id: previous; anchors.fill: parent; name: "vinx"; opacity: 0; visible: opacity > 0 }
    }
    property color _shown
    Component.onCompleted: _shown = logoColor
    onLogoColorChanged: {
        previous.color = _shown
        _shown = logoColor
        fade.restart()
    }
    NumberAnimation { id: fade; target: previous; property: "opacity"; from: 1; to: 0; duration: Theme.durSlow * 2 }
}
