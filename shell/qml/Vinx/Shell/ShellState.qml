pragma Singleton
import QtQuick

// État partagé entre la barre et la couche des panneaux (fenêtres distinctes en session réelle).
QtObject {
    // Panneau ouvert : "" | "system" | "control" | "calendar" | "confirm"
    property string openPanel: ""
    property rect anchorRect
    // Action en attente de confirmation : "poweroff" | "reboot" | "logout"
    property string pendingAction: ""
    property bool doNotDisturb: false

    function toggle(name, rect) {
        if (openPanel === name) { close(); return }
        anchorRect = rect
        openPanel = name
    }
    function close() { openPanel = ""; pendingAction = "" }
    function confirm(action) { pendingAction = action; openPanel = "confirm" }
}
