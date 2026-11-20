pragma Singleton
import QtQuick
import Vinx.System

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
    // Boîte d'extinction : « all », « poweroff », « reboot » ou « logout ».
    property string powerAction: "all"
    function askPower(action) {
        powerAction = action || "all"
        anchorRect = Qt.rect(0, 0, 0, 0)
        screenName = ""
        openPanel = ""
        openPanel = "power"
    }
    function confirm(action) { pendingAction = action; openPanel = "confirm" }
    function openDesktopMenu(rect, screen) { anchorRect = rect; screenName = screen || ""; openPanel = "desktop" }
    // Thème de fenêtre VinX (ADR 0024) : régénéré seulement quand l'accent ou le thème change
    // (un seul appel même avec plusieurs écrans).
    property string _windowThemeKey: ""
    function syncWindowTheme(accent, ink, dark) {
        const key = accent + ink + dark
        if (key === _windowThemeKey || Session.environment("VINX_SESSION") !== "1") return
        _windowThemeKey = key
        const args = ["--accent", accent, "--ink", ink, "--reconfigure"]
        if (dark) args.push("--dark")
        Session.run("vinx-window-theme", args)
    }
    // Écran de connexion (ADR 0041) : même clair/sombre et même accent que la session. pkexec ne demande
    // pas de mot de passe (action org.vinx.greeter-sync) ; appelé seulement quand la valeur change.
    function syncGreeter(dark, accentId) {
        const value = (dark ? "dark " : "light ") + accentId
        if (Session.environment("VINX_SESSION") !== "1" || String(Preferences.value("appearance/greeter", "")) === value) return
        Preferences.setValue("appearance/greeter", value)
        Session.run("pkexec", ["/usr/lib/vinx/vinx-greeter-sync", dark ? "dark" : "light", accentId])
    }

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
