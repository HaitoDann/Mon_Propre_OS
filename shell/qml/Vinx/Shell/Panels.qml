import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Couche des panneaux de la barre : menu système, centre de contrôle, calendrier, confirmation.
// Pilotée par ShellState ; remplit sa fenêtre (couche plein écran transparente en session réelle).
Item {
    id: layer
    anchors.fill: parent

    function sync() {
        const name = ShellState.openPanel
        const all = { system: systemMenu, control: control, calendar: calendar, confirm: confirm, dock: dockMenu, search: searchPanel }
        if (name === "search") ShellState.anchorRect = Qt.rect(layer.width / 2 - 1, layer.height * 0.12, 2, 1)
        for (const k in all) {
            const p = all[k]
            if (k === name) { p.anchorRect = ShellState.anchorRect; if (!p.open) p.show() }
            else if (p.open) { p.open = false }
        }
        if (name === "calendar") calendarContent.reset()
        if (name === "search") searchContent.reset()
    }
    Connections { target: ShellState; function onOpenPanelChanged() { layer.sync() } }
    // Touche Méta (KWin) ou autre programme : org.vinx.Shell.toggleSearch
    Connections { target: ShellService; function onSearchRequested() { ShellState.toggle("search", Qt.rect(0, 0, 0, 0)) } }
    Component.onCompleted: sync()

    Menu {
        id: systemMenu
        onClosed: if (ShellState.openPanel === "system") ShellState.close()
        model: [
            { text: qsTr("À propos de cet ordinateur"), iconName: "info" },
            { separator: true },
            { text: qsTr("Paramètres…"), iconName: "sliders" },
            { text: qsTr("Store…"), iconName: "bag" },
            { separator: true },
            { text: qsTr("Verrouiller l'écran"), iconName: "lock" },
            { text: qsTr("Mettre en veille"), iconName: "moon" },
            { text: qsTr("Fermer la session…"), iconName: "logout" },
            { text: qsTr("Redémarrer…"), iconName: "restart" },
            { text: qsTr("Éteindre…"), iconName: "power" }
        ]
        onTriggered: (i) => {
            ShellState.close()
            switch (i) {
            case 0: Session.launch("kinfocenter"); break
            case 2: Session.launch("systemsettings"); break
            case 3: Session.launch("plasma-discover"); break
            case 5: Session.lock(); break
            case 6: Session.suspend(); break
            case 7: ShellState.confirm("logout"); break
            case 8: ShellState.confirm("reboot"); break
            case 9: ShellState.confirm("poweroff"); break
            }
        }
    }

    // Menu contextuel d'une icône du dock (au-dessus de l'icône).
    Menu {
        id: dockMenu
        edge: Popover.Above
        align: Popover.Center
        onClosed: if (ShellState.openPanel === "dock") ShellState.close()
        readonly property var info: ShellState.dockMenu
        model: {
            const m = [{ header: info.name || "" }, { text: qsTr("Nouvelle fenêtre") }]
            m.push({ text: info.pinned ? qsTr("Retirer du dock") : qsTr("Garder dans le dock") })
            if (info.running) m.push({ separator: true }, { text: qsTr("Quitter") })
            return m
        }
        onTriggered: (i, entry) => {
            const idx = info.index
            ShellState.close()
            if (entry.text === qsTr("Nouvelle fenêtre")) Tasks.backend.newInstance(idx)
            else if (entry.text === qsTr("Quitter")) Tasks.backend.close(idx)
            else Tasks.backend.togglePin(idx)
        }
    }

    // Recherche globale, centrée en haut de l'écran.
    Popover {
        id: searchPanel
        padding: Theme.space3
        align: Popover.Center
        onClosed: if (ShellState.openPanel === "search") ShellState.close()
        Search { id: searchContent; onDone: ShellState.close() }
    }

    Popover {
        id: control
        padding: Theme.space3
        align: Popover.End
        onClosed: if (ShellState.openPanel === "control") ShellState.close()
        ControlCenter {}
    }

    Popover {
        id: calendar
        padding: Theme.space3
        align: Popover.End
        onClosed: if (ShellState.openPanel === "calendar") ShellState.close()
        CalendarPanel { id: calendarContent }
    }

    // Confirmation des actions irréversibles (éteindre, redémarrer, fermer la session).
    Popover {
        id: confirm
        padding: Theme.space4
        align: Popover.End
        onClosed: if (ShellState.openPanel === "confirm") ShellState.close()
        readonly property var texts: ({
            poweroff: [qsTr("Éteindre l'ordinateur ?"), qsTr("Éteindre")],
            reboot: [qsTr("Redémarrer l'ordinateur ?"), qsTr("Redémarrer")],
            logout: [qsTr("Fermer la session ?"), qsTr("Fermer la session")]
        })
        readonly property var current: texts[ShellState.pendingAction] || ["", ""]
        Column {
            spacing: Theme.space4
            width: 280
            Column {
                spacing: Theme.space1
                Label { text: confirm.current[0]; font.pixelSize: Theme.fsLg; font.weight: Font.DemiBold }
                Label { text: qsTr("Les documents non enregistrés seront perdus."); level: Label.Secondary; width: 280; wrapMode: Text.WordWrap }
            }
            Row {
                anchors.right: parent.right
                spacing: Theme.space2
                Button { text: qsTr("Annuler"); onClicked: ShellState.close() }
                Button {
                    text: confirm.current[1]
                    variant: Button.Primary
                    onClicked: {
                        const a = ShellState.pendingAction
                        ShellState.close()
                        if (a === "poweroff") Session.powerOff()
                        else if (a === "reboot") Session.reboot()
                        else if (a === "logout") Session.logout()
                    }
                }
            }
        }
    }
}
