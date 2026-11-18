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
    Osd { id: osd; anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 120 } }

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
            compare(Notifications.get(id).body, "Corps du message")       // balisage retiré
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

        function test_panel_remembers_its_screen() {
            ShellState.toggle("calendar", Qt.rect(10, 0, 20, 20), "HDMI-1")
            compare(ShellState.screenName, "HDMI-1")
            ShellState.toggle("calendar", Qt.rect(10, 0, 20, 20), "DP-2")     // même panneau, autre écran : il s'y déplace
            compare(ShellState.openPanel, "calendar")
            compare(ShellState.screenName, "DP-2")
            ShellState.toggle("calendar", Qt.rect(10, 0, 20, 20), "DP-2")     // même écran : fermeture
            compare(ShellState.openPanel, "")
        }

        SignalSpy { id: actionSpy; target: Notifications; signalName: "actionInvoked" }

        function test_notification_actions_and_default() {
            Notifications.clear()
            actionSpy.clear()
            const id = Notifications.notifyFull("Courrier", "Nouveau message", "Bonjour",
                                                ["default", "Ouvrir", "reply", "Répondre", "read", "Marquer comme lu"], {})
            const n = Notifications.get(id)
            compare(n.actions.length, 2)                 // « default » n'est pas un bouton
            compare(n.actions[0].label, "Répondre")
            verify(n.hasDefault)
            Notifications.invokeAction(id, "reply")
            compare(actionSpy.count, 1)
            compare(actionSpy.signalArguments[0][1], "reply")
            compare(Notifications.count, 0)              // une action retire la notification
            const id2 = Notifications.notifyFull("Courrier", "Autre", "", ["default", "Ouvrir"], {})
            Notifications.activate(id2)                   // clic = action par défaut
            compare(actionSpy.signalArguments[1][1], "default")
        }

        function test_notifications_grouped_by_app() {
            Notifications.clear()
            Notifications.notify("Firefox", "Téléchargement terminé")
            Notifications.notify("Courrier", "Message 1")
            Notifications.notify("Courrier", "Message 2")
            const g = Notifications.groups()
            compare(g.length, 2)
            compare(g[0].appName, "Courrier")             // groupe le plus récent d'abord
            compare(g[0].count, 2)
            compare(g[0].items[0].summary, "Message 2")
            Notifications.dismissApp("Courrier")
            compare(Notifications.count, 1)
            Notifications.clear()
        }

        function test_critical_notification_bypasses_dnd() {
            Notifications.clear()
            popupSpy.clear()
            Notifications.doNotDisturb = true
            Notifications.notifyFull("Énergie", "Batterie faible", "5 %", [], { urgency: 2 })
            compare(popupSpy.count, 1)
            compare(Notifications.get(popupSpy.signalArguments[0][0]).urgency, 2)
            Notifications.doNotDisturb = false
            Notifications.clear()
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

        function test_power_dialog_with_countdown() {
            ShellState.askPower("reboot")
            compare(ShellState.openPanel, "power")
            const dlg = findChild(panels, "powerDialog")
            verify(dlg.open)
            compare(dlg.preferred, "reboot")
            compare(dlg.remaining, 30)
            verify(findChild(dlg, "powerCountdown").text.indexOf("30") >= 0)
            dlg.close()
            compare(ShellState.openPanel, "")
            ShellState.askPower("all")
            compare(findChild(panels, "powerDialog").preferred, "poweroff")   // proposition par défaut
            ShellState.close()
        }

        function test_osd_shows_then_hides() {
            osd.show("volume", "volume", 64, "64 %")
            verify(osd.shown)
            compare(osd.percent, 64)
            tryCompare(osd, "shown", false, 3000)
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
