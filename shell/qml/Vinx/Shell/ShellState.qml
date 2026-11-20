pragma Singleton
import QtQuick
import Vinx.Theme
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

    // Couleur des espaces (ADR 0044, étape 2) : identifiant d'accent par espace (clé : identifiant
    // KWin du bureau), « » = accent global (vert par défaut). Préférence spaces/colors (JSON).
    property bool spaceTinted: false        // l'espace courant a sa propre couleur (indicateur, sans effet visuel sur le fond)
    readonly property var spaceColors: { Preferences.revision; try { return JSON.parse(String(Preferences.value("spaces/colors", "{}"))) || {} } catch (e) { return {} } }
    function spaceColorAt(i) {
        const b = Tasks.backend
        const id = b && b.desktopIds ? b.desktopIds[i] : undefined
        const c = id !== undefined ? spaceColors[id] : undefined
        return c && Theme.accents.some(a => a.id === c) ? c : ""
    }
    function setSpaceColorAt(i, accentId) {
        const b = Tasks.backend
        if (!b || !b.desktopIds || b.desktopIds[i] === undefined) return
        const m = Object.assign({}, spaceColors)
        const ids = b.desktopIds
        for (const k in m) if (ids.indexOf(k) < 0) delete m[k]      // espaces supprimés
        if (accentId) m[ids[i]] = accentId; else delete m[ids[i]]
        Preferences.setValue("spaces/colors", JSON.stringify(m))
    }
    readonly property bool anySpaceColored: Object.keys(spaceColors).length > 0
    // Couleur affichée pour l'espace i : la sienne, sinon l'accent global (vert par défaut).
    function spaceFillOrGlobal(i) {
        const f = spaceFill(i)
        if (f !== "") return f
        const id = String(Preferences.value("appearance/resolvedAccent", ""))
        return (Theme.accents.find(a => a.id === id) || Theme.accents[0]).fill
    }
    function spaceFill(i) {
        const c = spaceColorAt(i)
        const e = c ? Theme.accents.find(a => a.id === c) : null
        return e ? e.fill : ""
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
