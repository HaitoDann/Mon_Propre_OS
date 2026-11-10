import QtQuick
import QtTest
import Vinx.Theme
import Vinx.Controls
import Vinx.Shell
import Vinx.System

Item {
    id: root
    width: 1100; height: 700

    Background { id: background; anchors.fill: parent }
    TopBar { id: bar; anchors { left: parent.left; right: parent.right; top: parent.top } }
    Panels { id: panels; anchors.fill: parent }

    TestCase {
        name: "VinxShell"
        when: windowShown

        function cleanup() { ShellState.close(); Theme.dark = true; Notifications.doNotDisturb = false }

        SignalSpy { id: popupSpy; target: Notifications; signalName: "popup" }

        function test_notifications_history_and_dnd() {
            Notifications.clear()
            popupSpy.clear()
            const id = Notifications.notify("Test", "Bonjour", "<b>Corps</b> du message")
            compare(Notifications.count, 1)
            compare(popupSpy.count, 1)
            compare(popupSpy.signalArguments[0][3], "Corps du message")   // balisage retiré
            Notifications.doNotDisturb = true
            Notifications.notify("Test", "Silencieuse")
            compare(Notifications.count, 2)
            compare(popupSpy.count, 1)                                     // pas de bulle
            Notifications.dismiss(id)
            compare(Notifications.count, 1)
            Notifications.clear()
            compare(Notifications.count, 0)
        }

        function test_desktop_context_menu() {
            mouseClick(background, 600, 400, Qt.RightButton)
            compare(ShellState.openPanel, "desktop")
        }

        function test_bar_height() { compare(bar.height, Theme.topbarHeight) }

        function test_button_toggles_panel() {
            const b = bar.findButton("control")
            mouseClick(b)
            compare(ShellState.openPanel, "control")
            mouseClick(b)
            compare(ShellState.openPanel, "")
        }

        function test_only_one_panel_open() {
            bar.findButton("calendar").open()
            compare(ShellState.openPanel, "calendar")
            bar.findButton("system").open()
            compare(ShellState.openPanel, "system")
        }

        function test_outside_click_closes() {
            bar.findButton("calendar").open()
            wait(50)
            mouseClick(panels, 20, 650)
            compare(ShellState.openPanel, "")
        }

        function test_poweroff_requires_confirmation() {
            ShellState.confirm("poweroff")
            compare(ShellState.openPanel, "confirm")
            compare(ShellState.pendingAction, "poweroff")
            ShellState.close()
            compare(ShellState.pendingAction, "")
        }

        function test_panel_is_anchored_under_its_button() {
            const b = bar.findButton("control")
            b.open()
            wait(50)
            const p = b.mapToItem(root, 0, 0)
            verify(p.y + b.height <= Theme.topbarHeight)
        }
    }
}
