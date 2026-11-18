import QtQuick
import QtQuick.Window
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell

// Fenêtre « Autorisation nécessaire » (ADR 0028) : mot de passe administrateur pour une action
// système (installation, mise à jour, imprimante…). Pilotée par l'objet « agent » (C++).
Window {
    id: win
    width: 380
    height: col.implicitHeight + Theme.space6 * 2
    visible: agent.active
    flags: Qt.Dialog | Qt.WindowStaysOnTopHint
    title: qsTr("Autorisation nécessaire")
    color: Theme.surfaceWindow
    AppearanceSync {}
    onVisibleChanged: if (visible) { field.text = ""; field.forceActiveFocus(); requestActivate() }
    onClosing: (close) => { if (agent.active) agent.cancel() }

    Column {
        id: col
        x: Theme.space6; y: Theme.space6
        width: parent.width - Theme.space6 * 2
        spacing: Theme.space3

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56; height: 56; radius: 15
            color: Theme.surfaceSunken
            border.width: 1; border.color: Theme.border
            Icon { anchors.centerIn: parent; name: "lock"; width: 22; height: 22; color: Theme.text }
            Rectangle { width: 14; height: 14; radius: 7; color: Theme.accent; anchors { right: parent.right; bottom: parent.bottom; margins: -3 } }
        }
        Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: qsTr("Autorisation nécessaire"); font.pixelSize: Theme.fsLg; font.weight: Font.DemiBold }
        Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; level: Label.Secondary; text: agent.message }

        Rectangle {
            width: parent.width; height: 40
            radius: Theme.radiusMd
            color: Theme.surfaceSunken
            border.width: 2
            border.color: agent.error ? Theme.danger : field.activeFocus ? Theme.accentForeground : Theme.border
            TextInput {
                id: field
                anchors { fill: parent; leftMargin: Theme.space3; rightMargin: Theme.space3 }
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: Theme.text
                font.pixelSize: Theme.fsLg
                enabled: !agent.busy
                Accessible.name: qsTr("Mot de passe")
                onAccepted: if (text.length > 0) agent.submit(text)
                Label { visible: !field.text; anchors.verticalCenter: parent.verticalCenter; level: Label.Tertiary; text: qsTr("Mot de passe") }
            }
        }
        Label {
            width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            font.pixelSize: Theme.fsSm
            color: agent.error ? Theme.danger : Theme.textTertiary
            text: agent.error ? agent.error : qsTr("Mot de passe de %1").arg(agent.userName)
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.space2
            Button { text: qsTr("Annuler"); onClicked: agent.cancel() }
            Button { text: agent.busy ? qsTr("Vérification…") : qsTr("Autoriser"); variant: Button.Primary; enabled: field.text.length > 0 && !agent.busy; onClicked: agent.submit(field.text) }
        }
    }
    Connections { target: agent; function onChanged() { if (agent.error) { field.text = ""; field.forceActiveFocus() } } }
}
