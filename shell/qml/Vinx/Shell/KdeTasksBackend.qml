import QtQuick
import org.kde.taskmanager as TaskManager
import Vinx.System
import "AppStyle.js" as AppStyle

// Tâches réelles : gestionnaire de tâches de KDE (libtaskmanager), alimenté par KWin.
// Chargé dynamiquement par Tasks.qml ; absent hors session Plasma/KWin.
Item {
    id: root
    readonly property bool live: true
    readonly property alias model: tasks
    property var pinned: AppStyle.asList(Preferences.value("dock/pinned"), AppStyle.defaultPinned)
    readonly property int pinnedCount: tasks.launcherList.length
    readonly property string activeAppName: tasks.activeTask.valid
        ? (tasks.data(tasks.activeTask, TaskManager.AbstractTasksModel.AppName) || "") : ""

    // Bureaux virtuels de KWin.
    readonly property int desktopCount: desktops.numberOfDesktops
    readonly property int currentDesktopIndex: Math.max(0, desktops.desktopIds.indexOf(desktops.currentDesktop))
    readonly property var desktopNames: desktops.desktopNames
    // Paramètres → Bureau (ADR 0030) : nombre et noms des bureaux virtuels, sans le module KDE.
    function addDesktop() { desktops.requestCreateDesktop(desktops.numberOfDesktops) }
    function removeDesktop() { if (desktops.numberOfDesktops > 1) desktops.requestRemoveLastDesktop() }
    function renameDesktop(i, name) {
        if (i >= 0 && i < desktops.desktopIds.length)
            Session.callDBus("org.kde.KWin", "/VirtualDesktopManager", "org.kde.KWin.VirtualDesktopManager",
                             "setDesktopName", [String(desktops.desktopIds[i]), name])
    }
    function activateDesktop(i) { if (i >= 0 && i < desktops.desktopIds.length) desktops.requestActivate(desktops.desktopIds[i]) }

    function _launcherUrls(ids) { return ids.map(id => "applications:" + id + ".desktop") }

    TaskManager.VirtualDesktopInfo { id: desktops }
    TaskManager.ActivityInfo { id: activities }
    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false
        sortMode: TaskManager.TasksModel.SortManual
        separateLaunchers: false
        launchInPlace: true
        filterByVirtualDesktop: false
        filterByActivity: true
        activity: activities.currentActivity
        virtualDesktop: desktops.currentDesktop
        launcherList: root._launcherUrls(root.pinned)
    }

    function _index(i) { return tasks.makeModelIndex(i) }
    function _data(i, role) { return tasks.data(_index(i), role) }
    function _appId(i) {
        return AppStyle.normalizeId(_data(i, TaskManager.AbstractTasksModel.AppId), _data(i, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon))
    }

    // Incrémenté à chaque changement du modèle (liaisons QML qui appellent windows()).
    property int revision: 0
    Connections {
        target: tasks
        function onDataChanged() { root.revision++ }
        function onRowsInserted() { root.revision++ }
        function onRowsRemoved() { root.revision++ }
        function onModelReset() { root.revision++ }
    }
    // Index de la fenêtre j de l'application i (groupe) ou de l'application elle-même (une fenêtre).
    function _windowIndex(i, j) {
        return (_data(i, TaskManager.AbstractTasksModel.ChildCount) || 0) > 0 ? tasks.makeModelIndex(i, j) : _index(i)
    }
    function _win(idx) {
        return { title: tasks.data(idx, Qt.DisplayRole) || "",
                 minimized: !!tasks.data(idx, TaskManager.AbstractTasksModel.IsMinimized),
                 active: !!tasks.data(idx, TaskManager.AbstractTasksModel.IsActive) }
    }
    // Fenêtres de l'application i : [{ title, minimized, active }].
    function windows(i) {
        revision
        const n = _data(i, TaskManager.AbstractTasksModel.ChildCount) || 0
        const out = []
        if (n > 0)
            for (let j = 0; j < n; j++) out.push(_win(tasks.makeModelIndex(i, j)))
        else if (_data(i, TaskManager.AbstractTasksModel.IsWindow))
            out.push(_win(_index(i)))
        return out
    }
    // Ramène la fenêtre j (KWin la sort de la réduction) et l'active.
    function activateWindow(i, j) { tasks.requestActivate(_windowIndex(i, j)) }

    function minimizeWindow(i, j) { if (!windows(i)[j].minimized) tasks.requestToggleMinimized(_windowIndex(i, j)) }

    function isPinned(i) { return root.pinned.indexOf(_appId(i)) >= 0 }
    // Clic sur l'icône : lance, ramène ou réduit (une seule fenêtre). Plusieurs fenêtres : le dock
    // affiche la liste. (Activer un groupe n'a aucun effet dans libtaskmanager.)
    function activate(i) {
        const w = windows(i)
        if (w.length === 0) { tasks.requestActivate(_index(i)); return }
        if (w.length > 1) return
        const idx = _windowIndex(i, 0)
        if (w[0].active && !w[0].minimized) tasks.requestToggleMinimized(idx)
        else tasks.requestActivate(idx)
    }
    function newInstance(i) { tasks.requestNewInstance(_index(i)) }
    function close(i) { tasks.requestClose(_index(i)) }
    function togglePin(i) {
        const id = _appId(i)
        const list = root.pinned.slice()
        const at = list.indexOf(id)
        if (at >= 0) list.splice(at, 1); else list.push(id)
        root.pinned = list
        Preferences.setValue("dock/pinned", list)
    }
}
