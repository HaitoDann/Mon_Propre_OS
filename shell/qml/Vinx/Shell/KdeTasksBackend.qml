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
    function _appId(i) { return _data(i, TaskManager.AbstractTasksModel.AppId) }

    function isPinned(i) { return root.pinned.indexOf(_appId(i)) >= 0 }
    function activate(i) {
        const idx = _index(i)
        if (_data(i, TaskManager.AbstractTasksModel.IsActive) && !_data(i, TaskManager.AbstractTasksModel.IsLauncher))
            tasks.requestToggleMinimized(idx)
        else
            tasks.requestActivate(idx)
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
