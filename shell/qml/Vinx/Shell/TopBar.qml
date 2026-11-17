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
    function findButton(panel) { return ({ system: systemButton, search: searchButton, control: statusButton, calendar: clockButton })[panel] }
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
            rightPadding: Theme.space2
        }
        // Menu global (si le module appmenu de KDE est disponible, hors mode démo).
        Loader {
            active: true
            source: "KdeAppMenu.qml"
            onStatusChanged: if (status === Loader.Error) active = false
        }
    }

    // ---------- Droite ----------
    Row {
        anchors { right: parent.right; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter }
        spacing: 2

        // Vue d'ensemble de KWin : toutes les fenêtres, réduites comprises (aussi Méta+W).
        TopBarButton {
            id: overviewButton
            objectName: "overviewButton"
            command: true
            Accessible.name: qsTr("Toutes les fenêtres")
            onActivated: Session.invokeKWinShortcut("Overview")
            Icon { name: "grid"; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
        }
        WorkspaceIndicator { anchors.verticalCenter: parent.verticalCenter }

        // Mises à jour en cours d'installation (arrière-plan) : progression, clic → Store.
        Item {
            visible: Updates.applying
            width: visible ? updRow.implicitWidth + Theme.space2 * 2 : 0
            height: 24
            anchors.verticalCenter: parent.verticalCenter
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Mises à jour en cours : %1 %").arg(Math.max(0, Updates.progress))
            Row {
                id: updRow
                anchors.centerIn: parent
                spacing: 5
                Icon { name: "download"; color: Theme.accentForeground; anchors.verticalCenter: parent.verticalCenter }
                Label { text: Math.max(0, Updates.progress) + " %"; font.pixelSize: Theme.fsSm; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { anchors.fill: parent; onClicked: Session.launch("vinx-store", ["--page", "updates"]) }
        }

        TopBarButton {
            id: searchButton
            panel: "search"
            Accessible.name: qsTr("Rechercher")
            Icon { name: "search"; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
        }

        TopBarButton {
            id: statusButton
            panel: "control"
            Accessible.name: qsTr("Centre de contrôle")
            // Barre minimale : un indicateur n'apparaît que s'il apporte une information
            // (Wi-Fi, réseau coupé, son coupé, Ne pas déranger, batterie).
            Icon {
                id: netIcon
                visible: Network.available && (!Network.connected || Network.wireless)
                name: Network.connected ? "wifi" : "wifi-off"
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
            Icon {
                id: muteIcon
                visible: Audio.available && (Audio.muted || Audio.volume === 0)
                name: "volume-off"
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
            Icon {
                id: dndIcon
                visible: Notifications.doNotDisturb
                name: "bell-off"
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
            Row {
                id: batteryRow
                visible: Battery.present
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter
                Icon { name: Battery.charging ? "bolt" : "battery"; color: Battery.percentage <= 10 && !Battery.charging ? Theme.danger : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                // Pourcentage : seulement quand il devient utile (batterie faible) ou si demandé.
                Label {
                    visible: Battery.percentage <= 20 || (Preferences.revision, String(Preferences.value("topbar/batteryPercent", false)) === "true")
                    text: Battery.percentage + " %"; level: Label.Secondary; font.pixelSize: Theme.fsSm
                }
            }
            // Rien à signaler : une icône discrète donne accès au centre de contrôle.
            Icon {
                visible: !netIcon.visible && !muteIcon.visible && !dndIcon.visible && !batteryRow.visible
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
                text: bar.now.toLocaleString(Qt.locale(), (Preferences.revision, (String(Preferences.value("topbar/showDate", true)) === "false" ? "" : "ddd d MMM  ")
                      + (String(Preferences.value("clock/24h", true)) === "false" ? "h:mm AP" : "HH:mm")))
                font.weight: Font.Medium
            }
        }
    }
}
