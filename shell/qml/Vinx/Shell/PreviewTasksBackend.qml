import QtQuick
import Vinx.System
import "AppStyle.js" as AppStyle

// Modèle d'aperçu : mêmes rôles que le gestionnaire de tâches KDE, fenêtres simulées.
// Utilisé hors session (développement, tests, captures). Lancer une app ouvre une fenêtre fictive.
QtObject {
    id: root
    readonly property bool live: false
    readonly property var model: ListModel {}
    property var pinned: AppStyle.asList(Preferences.value("dock/pinned"), AppStyle.defaultPinned)
    readonly property int pinnedCount: pinned.length
    property string activeAppName: ""
    // Bureaux virtuels simulés.
    property int desktopCount: 3
    property int currentDesktopIndex: 0
    property var desktopNames: ["Bureau 1", "Bureau 2", "Bureau 3"]
    property var desktopIds: ["d1", "d2", "d3"]
    property int _nextId: 4
    function addDesktop() { desktopNames = desktopNames.concat(["Bureau " + (desktopCount + 1)]); desktopIds = desktopIds.concat(["d" + _nextId++]); desktopCount++ }
    function removeDesktop() { if (desktopCount > 1) { desktopCount--; desktopNames = desktopNames.slice(0, desktopCount); desktopIds = desktopIds.slice(0, desktopCount); currentDesktopIndex = Math.min(currentDesktopIndex, desktopCount - 1) } }
    function renameDesktop(i, name) { const n = desktopNames.slice(); n[i] = name; desktopNames = n }
    function removeDesktopAt(i) {
        if (desktopCount <= 1 || i < 0 || i >= desktopCount) return
        const n = desktopNames.slice(); n.splice(i, 1); desktopNames = n
        const ids = desktopIds.slice(); ids.splice(i, 1); desktopIds = ids
        desktopCount--
        if (currentDesktopIndex > i || currentDesktopIndex >= desktopCount) currentDesktopIndex = Math.max(0, currentDesktopIndex - 1)
    }
    function activateDesktop(i) { if (i >= 0 && i < desktopCount) currentDesktopIndex = i }

    // false : fenêtres purement simulées (démonstration, tests) — aucune application n'est lancée.
    property bool launchApps: true

    Component.onCompleted: rebuild()

    // Fenêtres simulées par application : { appId: [{ title, minimized }] } ; fenêtre active : "appId#n".
    property var _wins: ({})
    property string _activeKey: ""
    // Incrémenté à chaque changement de fenêtres (liaisons QML qui appellent windows()).
    property int revision: 0

    function _entry(appId, isPinned) {
        const info = Applications.info(appId)
        return { AppId: appId, AppName: info.valid ? info.name : appId, IsLauncher: isPinned, IsWindow: false,
                 IsActive: false, ChildCount: 0, IsStartup: false }
    }
    function _names() {
        const n = { "org.vinx.files": "Fichiers", "org.kde.dolphin": "Dolphin", "firefox-esr": "Firefox", "libreoffice-writer": "Documents",
                    "libreoffice-calc": "Tableur", "thunderbird": "Courrier", "org.vinx.store": "Store",
                    "org.vinx.settings": "Paramètres", "org.vinx.terminal": "Terminal" }
        return n
    }
    function _list(appId) { return _wins[appId] || [] }
    // Recopie l'état des fenêtres simulées dans les rôles du modèle (mêmes rôles que KDE).
    function _sync() {
        activeAppName = ""
        for (let i = 0; i < model.count; i++) {
            const e = model.get(i), w = _list(e.AppId)
            const activeHere = _activeKey.split("#")[0] === e.AppId
            model.setProperty(i, "IsWindow", w.length > 0)
            model.setProperty(i, "IsLauncher", w.length === 0 && pinned.indexOf(e.AppId) >= 0)
            model.setProperty(i, "ChildCount", w.length > 1 ? w.length : 0)
            model.setProperty(i, "IsActive", activeHere)
            model.setProperty(i, "IsMinimized", w.length > 0 && w.every(x => x.minimized))
            if (activeHere) activeAppName = e.AppName
        }
        revision++
    }
    function rebuild() {
        model.clear()
        const names = _names()
        for (const id of pinned) {
            const e = _entry(id, true)
            if (!Applications.info(id).valid && names[id]) e.AppName = names[id]
            e.IsMinimized = false
            model.append(e)
        }
        for (const id in _wins)
            if (pinned.indexOf(id) < 0 && _wins[id].length > 0) {
                const e = _entry(id, false)
                e.AppName = _wins[id].appName || e.AppName
                e.IsMinimized = false
                model.append(e)
            }
        _sync()
    }
    function _open(i) {
        const e = model.get(i)
        if (launchApps) Applications.launch(e.AppId)
        const w = _list(e.AppId).slice()
        w.push({ title: w.length === 0 ? e.AppName : e.AppName + " — " + (w.length + 1), minimized: false })
        w.appName = e.AppName
        _wins[e.AppId] = w
        _activeKey = e.AppId + "#" + (w.length - 1)
        _sync()
    }

    // Ouvre une application non épinglée (aperçu).
    function openApp(appId, name) {
        for (let i = 0; i < model.count; i++)
            if (model.get(i).AppId === appId) { activate(i); return }
        model.append({ AppId: appId, AppName: name || appId, IsLauncher: false, IsWindow: false, IsActive: false,
                       ChildCount: 0, IsStartup: false, IsMinimized: false })
        _open(model.count - 1)
    }

    function isPinned(i) { return pinned.indexOf(model.get(i).AppId) >= 0 }
    // Fenêtres de l'application i : [{ title, minimized, active }].
    function windows(i) {
        revision
        if (i < 0 || i >= model.count) return []
        const id = model.get(i).AppId
        return _list(id).map((w, j) => ({ title: w.title, minimized: w.minimized, active: _activeKey === id + "#" + j }))
    }
    // Ramène la fenêtre j de l'application i (la sort de la réduction) et l'active.
    function activateWindow(i, j) {
        const id = model.get(i).AppId, w = _list(id)
        if (j < 0 || j >= w.length) return
        w[j].minimized = false
        _activeKey = id + "#" + j
        _sync()
    }
    function minimizeWindow(i, j) {
        const id = model.get(i).AppId, w = _list(id)
        if (j < 0 || j >= w.length) return
        w[j].minimized = true
        if (_activeKey === id + "#" + j) _activeKey = ""
        _sync()
    }
    // Clic sur l'icône : lance, ramène ou réduit (une seule fenêtre). Plusieurs fenêtres : le dock
    // affiche la liste (rien à faire ici).
    function activate(i) {
        const id = model.get(i).AppId, w = _list(id)
        if (w.length === 0) { _open(i); return }
        if (w.length > 1) return
        if (_activeKey === id + "#0") { w[0].minimized = true; _activeKey = ""; _sync() }
        else activateWindow(i, 0)
    }
    function newInstance(i) { _open(i) }
    function close(i) {
        const id = model.get(i).AppId
        delete _wins[id]
        if (_activeKey.split("#")[0] === id) _activeKey = ""
        if (pinned.indexOf(id) < 0) model.remove(i)
        _sync()
    }
    function togglePin(i) {
        const id = model.get(i).AppId
        const list = pinned.slice()
        const at = list.indexOf(id)
        if (at >= 0) list.splice(at, 1); else list.push(id)
        pinned = list
        Preferences.setValue("dock/pinned", list)
        rebuild()
    }
}
