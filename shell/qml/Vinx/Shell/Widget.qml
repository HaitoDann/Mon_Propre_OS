import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Cadre commun des widgets du bureau : surface discrète, déplaçable, position mémorisée.
Surface {
    id: w
    property string key                       // ex. "clock" → préférences widgets/clock/x|y
    property point defaultPosition: Qt.point(24, 24)
    default property alias content: body.data
    property int padding: Theme.space4

    kind: Surface.Glass
    elevation: 1
    radius: Theme.radiusXl
    width: 260
    height: body.childrenRect.height + padding * 2

    function clamp(v, max) { return Math.max(8, Math.min(v, max)) }
    x: clamp(Number(Preferences.value("widgets/" + key + "/x", defaultPosition.x)), parent ? parent.width - width - 8 : 0)
    y: clamp(Number(Preferences.value("widgets/" + key + "/y", defaultPosition.y)), parent ? parent.height - height - 8 : 0)

    DragHandler {
        id: drag
        target: w
        onActiveChanged: if (!active) {
            Preferences.setValue("widgets/" + w.key + "/x", Math.round(w.x))
            Preferences.setValue("widgets/" + w.key + "/y", Math.round(w.y))
        }
    }
    opacity: drag.active ? 0.9 : 1

    Item {
        id: body
        x: w.padding; y: w.padding
        width: w.width - w.padding * 2
        height: childrenRect.height
    }
}
