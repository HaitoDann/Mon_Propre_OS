pragma Singleton
import QtQuick

// État partagé entre la barre et la couche des panneaux (fenêtres distinctes en session réelle).
QtObject {
    // Panneau ouvert : "" | "system" | "control" | "calendar" | "confirm" | "dock"
    property string openPanel: ""
    property rect anchorRect
    // Action en attente de confirmation : "poweroff" | "reboot" | "logout"
    property string pendingAction: ""
    // Menu contextuel du dock : { index, name, running, pinned }
    property var dockMenu: ({})

    function toggle(name, rect) {
        if (openPanel === name) { close(); return }
        anchorRect = rect
        openPanel = name
    }
    function close() { openPanel = ""; pendingAction = "" }
    function confirm(action) { pendingAction = action; openPanel = "confirm" }
    function openDesktopMenu(rect) { anchorRect = rect; openPanel = "desktop" }
    function openDockMenu(index, name, running, pinned, rect) {
        dockMenu = { index: index, name: name, running: running, pinned: pinned }
        anchorRect = rect
        openPanel = "dock"
    }
}
