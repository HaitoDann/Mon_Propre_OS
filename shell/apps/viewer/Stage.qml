import QtQuick
import Vinx.Viewer

// Image affichée : ajustée à la fenêtre (sans agrandir les petites images), zoom à la molette
// autour du pointeur, double-clic pour basculer entre « Ajuster » et 100 %, glisser pour se déplacer.
Item {
    id: stage
    property int turns: 0
    property real zoom: 1
    property bool fitted: true
    readonly property real zoomPercent: zoom * 100
    signal activity()

    readonly property Item picture: loader.item
    readonly property real sourceW: picture ? picture.implicitWidth : 0
    readonly property real sourceH: picture ? picture.implicitHeight : 0
    readonly property real turnedW: turns % 2 ? sourceH : sourceW
    readonly property real turnedH: turns % 2 ? sourceW : sourceH
    readonly property real fitZoom: turnedW > 0 && turnedH > 0 ? Math.min(1, (width - 24) / turnedW, (height - 24) / turnedH) : 1

    function fit() { fitted = true; zoom = fitZoom; flick.contentX = 0; flick.contentY = 0 }
    function actualSize() { zoomTo(1, width / 2, height / 2) }
    function zoomBy(factor, px, py) { zoomTo(zoom * factor, px === undefined ? width / 2 : px, py === undefined ? height / 2 : py) }
    function zoomTo(z, px, py) {
        const next = Math.max(Math.min(fitZoom, 0.1), Math.min(16, z))
        const cx = flick.contentX + px, cy = flick.contentY + py
        const r = next / zoom
        fitted = Math.abs(next - fitZoom) < 0.001
        zoom = next
        flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width, cx * r - px))
        flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, cy * r - py))
    }
    onFitZoomChanged: if (fitted) zoom = fitZoom
    onTurnsChanged: fit()

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: Math.max(width, stage.turnedW * stage.zoom)
        contentHeight: Math.max(height, stage.turnedH * stage.zoom)
        boundsBehavior: Flickable.StopAtBounds
        interactive: !stage.fitted
        clip: true
        Item {
            width: flick.contentWidth; height: flick.contentHeight
            Loader {
                id: loader
                anchors.centerIn: parent
                width: stage.sourceW * stage.zoom
                height: stage.sourceH * stage.zoom
                rotation: stage.turns * 90
                Behavior on rotation { RotationAnimation { duration: 180; direction: RotationAnimation.Shortest } }
                sourceComponent: Viewer.animated ? animatedPicture : stillPicture
                onLoaded: Qt.callLater(stage.fit)
            }
        }
    }
    Component {
        id: stillPicture
        Image {
            source: Viewer.current ? "file://" + Viewer.current : ""
            autoTransform: true
            asynchronous: true
            cache: false
            smooth: true
            mipmap: true
            onStatusChanged: if (status === Image.Ready) Qt.callLater(stage.fit)
        }
    }
    Component {
        id: animatedPicture
        AnimatedImage {
            source: Viewer.current ? "file://" + Viewer.current : ""
            autoTransform: true
            cache: false
            onStatusChanged: if (status === Image.Ready) Qt.callLater(stage.fit)
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        propagateComposedEvents: true
        hoverEnabled: true
        onPositionChanged: stage.activity()
        onDoubleClicked: (m) => stage.fitted ? stage.zoomTo(1, m.x, m.y) : stage.fit()
        onPressed: (m) => { m.accepted = false }
        onWheel: (w) => {
            stage.activity()
            const steps = w.angleDelta.y / 120
            if (steps !== 0) stage.zoomBy(Math.pow(1.2, steps), w.x, w.y)
        }
    }
}
