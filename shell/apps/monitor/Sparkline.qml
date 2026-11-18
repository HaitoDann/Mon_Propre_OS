import QtQuick

// Mini-graphique : courbe des 60 dernières mesures, aire légèrement teintée.
// maximum = 0 : échelle automatique (débits disque et réseau).
Canvas {
    id: root
    property var values: []
    property real maximum: 100
    property color color: "#10DD8C"
    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const n = values.length
        if (n < 2) return
        let top = maximum
        if (top <= 0) { top = 1; for (let i = 0; i < n; ++i) top = Math.max(top, values[i]) ; top *= 1.15 }
        const step = width / (n - 1)
        const y = v => height - 1 - Math.min(1, Math.max(0, v / top)) * (height - 2)
        ctx.beginPath()
        ctx.moveTo(0, y(values[0]))
        for (let i = 1; i < n; ++i) ctx.lineTo(i * step, y(values[i]))
        ctx.lineWidth = 1.5
        ctx.strokeStyle = root.color
        ctx.stroke()
        ctx.lineTo(width, height); ctx.lineTo(0, height); ctx.closePath()
        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.14)
        ctx.fill()
    }
}
