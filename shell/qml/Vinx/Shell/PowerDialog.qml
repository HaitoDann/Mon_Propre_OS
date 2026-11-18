import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Boîte d'extinction VinX (ADR 0028) : remplace l'écran de déconnexion de KDE (bouton
// d'alimentation, applications). Veille, redémarrer, éteindre, fermer la session ; l'action
// proposée s'exécute seule au bout de 30 s.
Popover {
    id: dlg
    objectName: "powerDialog"
    edge: Popover.Below
    align: Popover.Center
    padding: Theme.space5
    // « all », « poweroff », « reboot » ou « logout »
    property string action: "all"
    property int remaining: 30
    readonly property string preferred: action === "all" ? "poweroff" : action
    readonly property var choices: [
        { id: "suspend", title: qsTr("Veille"), icon: "moon" },
        { id: "reboot", title: qsTr("Redémarrer"), icon: "restart" },
        { id: "poweroff", title: qsTr("Éteindre"), icon: "power" },
        { id: "logout", title: qsTr("Fermer la session"), icon: "logout" }
    ]
    function run(id) {
        countdown.stop()
        close()
        if (id === "poweroff") Session.powerOff()
        else if (id === "reboot") Session.reboot()
        else if (id === "logout") Session.logout()
        else if (id === "suspend") Session.suspend()
    }
    onOpenChanged: { if (open) { remaining = 30; countdown.restart() } else countdown.stop() }
    Timer {
        id: countdown
        interval: 1000; repeat: true
        onTriggered: { dlg.remaining--; if (dlg.remaining <= 0) dlg.run(dlg.preferred) }
    }

    Column {
        width: 400
        spacing: Theme.space4
        Column {
            width: parent.width
            spacing: Theme.space1
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fsLg; font.weight: Font.DemiBold
                text: dlg.preferred === "reboot" ? qsTr("Redémarrer l'ordinateur ?")
                    : dlg.preferred === "logout" ? qsTr("Fermer la session ?") : qsTr("Éteindre l'ordinateur ?")
            }
            Label {
                objectName: "powerCountdown"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                level: Label.Secondary
                text: (dlg.preferred === "reboot" ? qsTr("Redémarrage automatique dans %1 s.")
                      : dlg.preferred === "logout" ? qsTr("Fermeture automatique dans %1 s.")
                      : qsTr("Extinction automatique dans %1 s.")).arg(dlg.remaining)
            }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.space3
            Repeater {
                model: dlg.choices
                Column {
                    required property var modelData
                    readonly property bool main: modelData.id === dlg.preferred
                    spacing: Theme.space2
                    width: 88
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 60; height: 60; radius: 18
                        color: parent.main ? "#FF5F57" : tileMouse.containsMouse ? Theme.surfaceActive : Theme.surfaceSunken
                        border.width: parent.main ? 0 : 1
                        border.color: Theme.border
                        Icon { anchors.centerIn: parent; name: modelData.icon; color: parent.parent.main ? "#FFFFFF" : Theme.text }
                        MouseArea { id: tileMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dlg.run(modelData.id) }
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.title
                    }
                    Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: modelData.title; font.pixelSize: Theme.fsSm; wrapMode: Text.WordWrap }
                }
            }
        }
        Button { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Annuler"); onClicked: dlg.close() }
    }
}
