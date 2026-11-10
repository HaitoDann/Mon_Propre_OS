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
    function activateDesktop(i) { if (i >= 0 && i < desktopCount) currentDesktopIndex = i }

    // false : fenêtres purement simulées (démonstration, tests) — aucune application n'est lancée.
    property bool launchApps: true

    Component.onCompleted: rebuild()

    function _entry(appId, isPinned) {
        const info = Applications.info(appId)
        return { AppId: appId, AppName: info.valid ? info.name : appId, IsLauncher: isPinned, IsWindow: false,
                 IsActive: false, ChildCount: 0, IsStartup: false }
    }
    function _names() {
        const n = { "org.kde.dolphin": "Fichiers", "firefox-esr": "Firefox", "libreoffice-writer": "Documents",
                    "libreoffice-calc": "Tableur", "thunderbird": "Courrier", "org.vinx.store": "Store",
                    "org.vinx.settings": "Paramètres", "org.kde.konsole": "Terminal" }
        return n
    }
    function rebuild() {
        const running = []
        for (let i = 0; i < model.count; i++) {
            const e = model.get(i)
            if (e.IsWindow) running.push({ AppId: e.AppId, AppName: e.AppName, IsActive: e.IsActive, ChildCount: e.ChildCount })
        }
        model.clear()
        const names = _names()
        for (const id of pinned) {
            const e = _entry(id, true)
            if (!Applications.info(id).valid && names[id]) e.AppName = names[id]
            const r = running.find(x => x.AppId === id)
            if (r) { e.IsWindow = true; e.IsLauncher = false; e.IsActive = r.IsActive; e.ChildCount = r.ChildCount }
            model.append(e)
        }
        for (const r of running) {
            if (pinned.indexOf(r.AppId) < 0)
                model.append({ AppId: r.AppId, AppName: r.AppName, IsLauncher: false, IsWindow: true,
                               IsActive: r.IsActive, ChildCount: r.ChildCount, IsStartup: false })
        }
        _updateActive()
    }
    function _updateActive() {
        activeAppName = ""
        for (let i = 0; i < model.count; i++)
            if (model.get(i).IsActive) activeAppName = model.get(i).AppName
    }
    function _setActive(i) {
        for (let k = 0; k < model.count; k++) model.setProperty(k, "IsActive", k === i)
        _updateActive()
    }

    // Ouvre une application non épinglée (aperçu).
    function openApp(appId, name) {
        for (let i = 0; i < model.count; i++)
            if (model.get(i).AppId === appId) { activate(i); return }
        model.append({ AppId: appId, AppName: name || appId, IsLauncher: false, IsWindow: true, IsActive: false, ChildCount: 1, IsStartup: false })
        _setActive(model.count - 1)
    }

    function isPinned(i) { return pinned.indexOf(model.get(i).AppId) >= 0 }
    function activate(i) {
        const e = model.get(i)
        if (!e.IsWindow) {
            if (launchApps) Applications.launch(e.AppId)
            model.setProperty(i, "IsWindow", true)
            model.setProperty(i, "IsLauncher", false)
            model.setProperty(i, "ChildCount", 1)
            _setActive(i)
        } else if (e.IsActive) {
            model.setProperty(i, "IsActive", false)   // clic sur l'app active : réduction
            _updateActive()
        } else {
            _setActive(i)
        }
    }
    function newInstance(i) {
        const e = model.get(i)
        if (launchApps) Applications.launch(e.AppId)
        model.setProperty(i, "IsWindow", true)
        model.setProperty(i, "ChildCount", e.ChildCount + 1)
        _setActive(i)
    }
    function close(i) {
        const id = model.get(i).AppId
        model.setProperty(i, "IsWindow", false); model.setProperty(i, "IsActive", false); model.setProperty(i, "ChildCount", 0)
        if (pinned.indexOf(id) < 0) model.remove(i)
        else model.setProperty(i, "IsLauncher", true)
        _updateActive()
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
