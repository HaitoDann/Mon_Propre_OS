import QtQuick
import Vinx.Theme

// Curseur horizontal (luminosité, volume, taille du dock…).
Item {
    id: root
    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: (to - from) / 20
    // snap : la valeur reste un multiple du pas, même à la souris (tailles en pixels…).
    property bool snap: false
    signal moved(real value)

    function setValue(v) {
        if (snap && stepSize > 0) v = from + Math.round((v - from) / stepSize) * stepSize
        const clamped = Math.max(from, Math.min(to, v))
        if (clamped !== value) { value = clamped; moved(value) }
    }
    readonly property real position: to > from ? (value - from) / (to - from) : 0

    implicitWidth: 200; implicitHeight: 22
    activeFocusOnTab: true
    Keys.onRightPressed: setValue(value + stepSize)
    Keys.onUpPressed: setValue(value + stepSize)
    Keys.onLeftPressed: setValue(value - stepSize)
    Keys.onDownPressed: setValue(value - stepSize)
    Accessible.role: Accessible.Slider

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.dark ? Theme.surfaceHover : Theme.borderStrong
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accentForeground

        Rectangle {
            width: knob.x + knob.width
            height: parent.height
            radius: parent.radius
            color: Theme.accent
            border.width: Theme.dark ? 0 : 1
            border.color: Theme.accentForeground
        }
        Rectangle {
            id: knob
            width: parent.height; height: width; radius: width / 2
            x: root.position * (parent.width - width)
            color: "white"
            border.width: 1
            border.color: Theme.dark ? Theme.borderStrong : Theme.accentForeground
        }
    }
    MouseArea {
        anchors.fill: parent
        preventStealing: true
        function update(mx) {
            const p = (mx - knob.width / 2) / (width - knob.width)
            root.setValue(root.from + Math.max(0, Math.min(1, p)) * (root.to - root.from))
        }
        onPressed: (m) => update(m.x)
        onPositionChanged: (m) => update(m.x)
    }
}
