import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Barre supérieure de VinX OS (34 px) : menu système à gauche, état du système et heure à droite.
Rectangle {
    id: bar
    // Nom de l'application active (fourni par le gestionnaire de tâches).
    readonly property string activeTitle: Tasks.backend && Tasks.backend.activeAppName ? Tasks.backend.activeAppName : qsTr("Bureau")
    property date now: new Date()

    implicitHeight: Theme.topbarHeight

    // Bouton associé à un panneau (ouverture au démarrage, tests).
    function findButton(panel) { return ({ system: systemButton, control: statusButton, calendar: clockButton })[panel] }
    color: Theme.surfaceGlass
    Behavior on color { ColorAnimation { duration: Theme.durNormal } }

    Rectangle {   // filet inférieur
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.border
    }

    Timer {
        interval: 1000 * (60 - new Date().getSeconds())   // aligné sur la minute
        running: true; repeat: true
        onTriggered: { bar.now = new Date(); interval = 60000 }
    }

    // ---------- Gauche ----------
    Row {
        anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter }
        spacing: 2

        TopBarButton {
            id: systemButton
            panel: "system"
            Accessible.name: qsTr("Menu système")
            Icon { name: "vinx"; width: 19; height: 14; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
        }
        Label {
            text: bar.activeTitle
            font.weight: Font.DemiBold
            height: 24
            leftPadding: Theme.space2
        }
    }

    // ---------- Droite ----------
    Row {
        anchors { right: parent.right; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter }
        spacing: 2

        TopBarButton {
            id: statusButton
            panel: "control"
            Accessible.name: qsTr("Centre de contrôle")
            Icon {
                visible: Network.available
                name: Network.connected ? "wifi" : "wifi-off"
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
            Icon {
                visible: Audio.available
                name: Audio.muted || Audio.volume === 0 ? "volume-off" : "volume"
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
            Icon {
                visible: ShellState.doNotDisturb
                name: "bell-off"
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
            Row {
                visible: Battery.present
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter
                Icon { name: Battery.charging ? "bolt" : "battery"; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                Label { text: Battery.percentage + " %"; level: Label.Secondary; font.pixelSize: Theme.fsSm }
            }
            // Sans aucun indicateur disponible, une icône d'accès reste visible.
            Icon {
                visible: !Network.available && !Audio.available && !Battery.present
                name: "sliders"
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        TopBarButton {
            id: clockButton
            panel: "calendar"
            Accessible.name: qsTr("Calendrier et notifications")
            Label {
                text: bar.now.toLocaleString(Qt.locale(), "ddd d MMM  HH:mm")
                font.weight: Font.Medium
            }
        }
    }
}
