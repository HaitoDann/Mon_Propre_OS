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
            backend.openApp("org.kde.konsole", "Terminal")
            compare(backend.model.count, before + 1)
            compare(backend.model.get(before).AppId, "org.kde.konsole")
            backend.close(before)
            compare(backend.model.count, before)
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
