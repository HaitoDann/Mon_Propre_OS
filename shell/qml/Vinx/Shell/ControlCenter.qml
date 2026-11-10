import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Contenu du centre de contrôle : réseau, Bluetooth, concentration, apparence, son, batterie.
Column {
    spacing: Theme.space3
    width: 332

    Grid {
        columns: 2
        spacing: Theme.space2
        Tile {
            width: 162
            enabled: Network.available
            iconName: Network.wirelessEnabled ? "wifi" : "wifi-off"
            title: qsTr("Wi-Fi")
            subtitle: !Network.available ? qsTr("Indisponible")
                    : !Network.wirelessEnabled ? qsTr("Désactivé")
                    : Network.wireless ? Network.connectionName : qsTr("Activé")
            checked: Network.wirelessEnabled
            onClicked: Network.wirelessEnabled = !Network.wirelessEnabled
        }
        Tile {
            width: 162
            enabled: Bluetooth.available
            iconName: "bluetooth"
            title: qsTr("Bluetooth")
            subtitle: !Bluetooth.available ? qsTr("Indisponible") : Bluetooth.powered ? qsTr("Activé") : qsTr("Désactivé")
            checked: Bluetooth.powered
            onClicked: Bluetooth.powered = !Bluetooth.powered
        }
        Tile {
            width: 162
            iconName: ShellState.doNotDisturb ? "bell-off" : "bell"
            title: qsTr("Ne pas déranger")
            subtitle: ShellState.doNotDisturb ? qsTr("Activé") : qsTr("Désactivé")
            checked: ShellState.doNotDisturb
            onClicked: ShellState.doNotDisturb = !ShellState.doNotDisturb
        }
        Tile {
            width: 162
            iconName: Theme.dark ? "moon" : "sun"
            title: qsTr("Apparence")
            subtitle: Theme.dark ? qsTr("Sombre") : qsTr("Claire")
            checked: Theme.dark
            onClicked: Theme.dark = !Theme.dark
        }
    }

    Column {
        visible: Audio.available
        spacing: 6
        width: parent.width
        Label { text: qsTr("Son"); font.weight: Font.DemiBold; font.pixelSize: Theme.fsSm }
        Row {
            spacing: Theme.space2
            IconButton {
                flat: true
                width: 24; height: 24
                iconName: Audio.muted || Audio.volume === 0 ? "volume-off" : "volume"
                toolTip: Audio.muted ? qsTr("Réactiver le son") : qsTr("Couper le son")
                onClicked: Audio.muted = !Audio.muted
                anchors.verticalCenter: parent.verticalCenter
            }
            Slider {
                width: 300
                value: Audio.muted ? 0 : Audio.volume
                onMoved: (v) => Audio.volume = v
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    Item {
        width: parent.width
        height: 28
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: Battery.present
            Icon { name: Battery.charging ? "bolt" : "battery"; color: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }
            Label {
                level: Label.Secondary
                font.pixelSize: Theme.fsSm
                text: Battery.charging ? qsTr("Batterie %1 % · en charge").arg(Battery.percentage) : qsTr("Batterie %1 %").arg(Battery.percentage)
            }
        }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 6
            IconButton {
                iconName: "sliders"
                toolTip: qsTr("Paramètres")
                onClicked: { ShellState.close(); Session.launch("systemsettings") }
            }
            IconButton {
                iconName: "power"
                toolTip: qsTr("Éteindre…")
                onClicked: ShellState.confirm("poweroff")
            }
        }
    }
}
