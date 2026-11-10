pragma Singleton
import QtQuick

// État partagé entre la barre et la couche des panneaux (fenêtres distinctes en session réelle).
QtObject {
    // Panneau ouvert : "" | "system" | "control" | "calendar" | "confirm" | "dock"
    property string openPanel: ""
    property rect anchorRect
    // Écran où s'ouvre le panneau (multi-écran) ; "" = écran principal.
    property string screenName: ""
    // Action en attente de confirmation : "poweroff" | "reboot" | "logout"
    property string pendingAction: ""
    // Menu contextuel du dock : { index, name, running, pinned }
    property var dockMenu: ({})

    function toggle(name, rect, screen) {
        if (openPanel === name && screenName === (screen || "")) { close(); return }
        anchorRect = rect
        screenName = screen || ""
        openPanel = name
    }
    function close() { openPanel = ""; pendingAction = "" }
    function confirm(action) { pendingAction = action; openPanel = "confirm" }
    function openDesktopMenu(rect, screen) { anchorRect = rect; screenName = screen || ""; openPanel = "desktop" }
    function openDockMenu(index, name, running, pinned, rect, screen) {
        dockMenu = { index: index, name: name, running: running, pinned: pinned }
        anchorRect = rect
        screenName = screen || ""
        openPanel = "dock"
    }
}
