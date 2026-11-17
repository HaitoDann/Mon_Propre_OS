pragma Singleton
import QtQuick

// État partagé entre la barre et la couche des panneaux (fenêtres distinctes en session réelle).
QtObject {
    // Panneau ouvert : "" | "system" | "control" | "calendar" | "confirm" | "dock" | "windows" | …
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
    // Menu global : action racine (QAction) du menu ouvert.
    property var appMenuAction: null
    function openAppMenu(rect, action, screen) {
        anchorRect = rect; screenName = screen || ""; appMenuAction = action
        openPanel = ""; openPanel = "appmenu"
    }
    function close() { openPanel = ""; pendingAction = "" }
    function confirm(action) { pendingAction = action; openPanel = "confirm" }
    function openDesktopMenu(rect, screen) { anchorRect = rect; screenName = screen || ""; openPanel = "desktop" }
    // Liste des fenêtres d'une application du dock : { index, name }
    property var windowList: ({})
    function openWindowList(index, name, rect, screen) {
        if (openPanel === "windows" && windowList.index === index) { close(); return }
        windowList = { index: index, name: name }
        anchorRect = rect
        screenName = screen || ""
        openPanel = "windows"
    }
    function openDockMenu(index, name, running, pinned, rect, screen) {
        dockMenu = { index: index, name: name, running: running, pinned: pinned }
        anchorRect = rect
        screenName = screen || ""
        openPanel = "dock"
    }
}
