import QtQuick
import QtTest
import Vinx.Theme
import Vinx.Shell

Item {
    id: root
    width: 1100; height: 700

    TopBar { id: bar; anchors { left: parent.left; right: parent.right; top: parent.top } }
    Dock { id: dock; anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 160 }
    Panels { anchors.fill: parent }

    TestCase {
        name: "VinxDock"
        when: windowShown
        readonly property var backend: Tasks.backend

        function initTestCase() { backend.launchApps = false }
        function cleanup() { ShellState.close() }

        function test_preview_backend_and_pinned_items() {
            verify(!Tasks.live)
            compare(backend.model.count, backend.pinnedCount)
            verify(backend.pinnedCount >= 5)
        }

        function test_click_opens_and_activates() {
            const it = dock.itemAt(0)
            verify(!it.running)
            mouseClick(it)
            verify(it.running)
            verify(it.active)
            compare(bar.activeTitle, it.appName)
            mouseClick(it)                       // clic sur l'app active : réduite
            verify(!it.active)
            compare(bar.activeTitle, "Bureau")
        }

        function test_context_menu_and_quit() {
            const it = dock.itemAt(1)
            mouseClick(it)
            verify(it.running)
            mouseClick(it, it.width / 2, it.height / 2, Qt.RightButton)
            compare(ShellState.openPanel, "dock")
            compare(ShellState.dockMenu.index, 1)
            verify(ShellState.dockMenu.running)
            backend.close(1)
            verify(!dock.itemAt(1).running)
        }

        function test_unpinned_app_appears_after_pinned() {
            const before = backend.model.count
            backend.openApp("org.vinx.terminal", "Terminal")
            compare(backend.model.count, before + 1)
            compare(backend.model.get(before).AppId, "org.vinx.terminal")
            backend.close(before)
            compare(backend.model.count, before)
        }

        function test_minimized_window_is_marked_and_restored() {
            const it = dock.itemAt(4)
            mouseClick(it)                               // ouvre
            compare(it.windowStates.length, 1)
            verify(!it.windowStates[0].minimized)
            mouseClick(it)                               // active : réduite
            verify(it.windowStates[0].minimized)
            verify(!it.active)
            mouseClick(it)                               // une seule fenêtre : ramenée directement
            verify(!it.windowStates[0].minimized)
            verify(it.active)
            backend.close(4)
        }

        function test_several_windows_open_the_list() {
            const it = dock.itemAt(4)
            mouseClick(it)
            backend.newInstance(4)
            backend.minimizeWindow(4, 0)
            compare(it.windowStates.length, 2)
            verify(it.windowStates[0].minimized)
            mouseClick(it)                               // plusieurs fenêtres : liste
            compare(ShellState.openPanel, "windows")
            compare(ShellState.windowList.index, 4)
            const menu = findChild(root, "windowMenu")
            compare(menu.wins.length, 2)
            compare(menu.model[1].shortcut, "Réduite")
            menu.triggered(1, menu.model[1])             // choisir la fenêtre réduite
            compare(ShellState.openPanel, "")
            verify(!it.windowStates[0].minimized)
            verify(it.windowStates[0].active)
            mouseClick(it)                               // second clic sur l'icône : referme la liste
            mouseClick(it)
            compare(ShellState.openPanel, "")
            backend.close(4)
        }

        function test_overview_button() {
            verify(findChild(bar, "overviewButton") !== null)
        }

        function test_workspaces() {
            compare(backend.desktopCount, 3)
            backend.activateDesktop(2)
            compare(backend.currentDesktopIndex, 2)
            backend.activateDesktop(7)                 // hors limites : ignoré
            compare(backend.currentDesktopIndex, 2)
            backend.activateDesktop(0)
        }

        function test_magnification_grows_hovered_icon() {
            const it = dock.itemAt(3)
            mouseMove(it, it.width / 2, it.height / 2)
            tryVerify(() => it.size > Theme.dockIcon + 4)
            mouseMove(root, 10, 10)
            tryCompare(it, "size", Theme.dockIcon)
        }
    }
}
