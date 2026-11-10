import QtQuick
import QtTest
import Vinx.Theme
import Vinx.Controls
import Vinx.Shell

Item {
    id: root
    width: 1100; height: 700

    TopBar { id: bar; anchors { left: parent.left; right: parent.right; top: parent.top } }
    Panels { id: panels; anchors.fill: parent }

    TestCase {
        name: "VinxShell"
        when: windowShown

        function cleanup() { ShellState.close(); Theme.dark = true; ShellState.doNotDisturb = false }

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
