import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell

// Écran de verrouillage de VinX OS, chargé par kscreenlocker (KDE) via le paquet d'apparence
// org.vinx.desktop. La sécurité reste celle de KDE : l'authentification passe par l'objet
// « authenticator » (PAM) et le verrouilleur refuse de se fermer tant qu'il n'a pas validé
// le mot de passe. En cas d'erreur de chargement, KDE affiche son écran de secours.
//
// Interface fournie par kscreenlocker (version 2) : authenticator, kscreenlocker_userName,
// propriétés « locked », « suspendToRamSupported », signal « suspendToRam ».
Item {
    id: root

    property bool locked: false
    property bool suspendToRamSupported: false
    property bool suspendToDiskSupported: false
    signal suspendToRam()
    signal suspendToDisk()

    property string message: ""
    property date now: new Date()

    AppearanceSync {}

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // ---------- Fond : le fond d'écran du bureau, assombri ----------
    Rectangle { anchors.fill: parent; color: Theme.background }
    // Même fond que le bureau (dont « VinX Logo » à la couleur d'accent).
    Background { anchors.fill: parent; interactive: false }
    Rectangle { anchors.fill: parent; color: Theme.background; opacity: 0.3 }

    // ---------- Heure et date ----------
    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.16 }
        spacing: Theme.space2
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "HH:mm")
            color: Theme.text
            font.pixelSize: 96
            font.weight: Font.Light
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: { const s = root.now.toLocaleDateString(Qt.locale(), "dddd d MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
            color: Theme.textSecondary
            font.pixelSize: Theme.fsLg
        }
    }

    // ---------- Déverrouillage ----------
    Column {
        id: form
        visible: root.locked
        // Arrivée signature : glissement le long de la diagonale du biseau.
        opacity: root.locked ? 1 : 0
        transform: Translate { x: root.locked ? 0 : 16; y: root.locked ? 0 : -16
            Behavior on x { NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutCubic } } }
        Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.verticalCenter; topMargin: Theme.space5 }
        spacing: Theme.space3
        width: 300

        // Pastille avec l'initiale de l'utilisateur
        Bevel {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 68; height: 68; cut: 15
            color: Theme.accent
            Label {
                anchors.centerIn: parent
                text: (kscreenlocker_userName || "?").charAt(0).toUpperCase()
                color: Theme.accentText
                font.pixelSize: 30
                font.weight: Font.DemiBold
            }
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: kscreenlocker_userName || qsTr("Session verrouillée")
            color: Theme.text
            font.pixelSize: Theme.fsLg
            font.weight: Font.DemiBold
        }

        // Champ de mot de passe
        Bevel {
            width: parent.width; height: 42; cut: 10
            color: Theme.surfaceSunken
            borderWidth: password.activeFocus ? 2 : 1
            borderColor: password.activeFocus ? Theme.accentForeground : Theme.borderStrong
            opacity: authenticator.busy ? 0.6 : 1

            TextInput {
                id: password
                anchors { left: parent.left; right: go.left; leftMargin: Theme.space3; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: Theme.text
                selectionColor: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsLg
                clip: true
                focus: true
                enabled: !authenticator.busy
                Accessible.name: qsTr("Mot de passe")
                Keys.onReturnPressed: root.tryUnlock()
                Keys.onEnterPressed: root.tryUnlock()
                Keys.onEscapePressed: text = ""
                Label {
                    visible: password.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Mot de passe")
                    color: Theme.textTertiary
                    font.pixelSize: Theme.fsLg
                }
            }
            // Bouton « valider »
            Bevel {
                id: go
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                width: 32; height: 30; cut: 8
                color: password.text !== "" ? Theme.accent : Theme.surfaceActive
                Icon { anchors.centerIn: parent; name: "chevron-r"; color: password.text !== "" ? Theme.accentText : Theme.text }
                MouseArea { anchors.fill: parent; onClicked: root.tryUnlock() }
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Déverrouiller")
            }
        }

        Label {
            id: info
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.message
            color: Theme.danger
            font.pixelSize: Theme.fsSm
            visible: text !== ""
        }
    }

    // ---------- Actions en bas ----------
    Row {
        visible: root.locked && root.suspendToRamSupported
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.space6 }
        spacing: Theme.space4
        Bevel {
            width: sleepRow.implicitWidth + Theme.space4 * 2; height: 34; cut: 9
            color: sleepMouse.containsMouse ? Theme.surfaceActive : Theme.surfaceGlassStrong
            Row {
                id: sleepRow
                anchors.centerIn: parent
                spacing: Theme.space2
                Icon { name: "moon"; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                Label { text: qsTr("Mettre en veille"); color: Theme.text }
            }
            MouseArea { id: sleepMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.suspendToRam() }
        }
    }

    // ---------- Authentification (kscreenlocker / PAM) ----------
    function tryUnlock() {
        if (authenticator.busy) return
        root.message = ""
        authenticator.startAuthenticating()
    }

    Connections {
        target: authenticator
        // PAM demande le secret : on lui transmet le mot de passe saisi.
        function onPromptForSecretChanged() { authenticator.respond(password.text) }
        function onFailed() {
            root.message = qsTr("Mot de passe incorrect.")
            password.selectAll()
            password.forceActiveFocus()
        }
        function onInfoMessageChanged() { if (authenticator.infoMessage) root.message = authenticator.infoMessage }
        function onErrorMessageChanged() { if (authenticator.errorMessage) root.message = authenticator.errorMessage }
        function onBusyChanged() { if (!authenticator.busy) password.forceActiveFocus() }
        // Mot de passe validé : kscreenlocker ne ferme l'écran que dans ce cas.
        function onSucceeded() { Qt.quit() }
    }

    // Toute frappe ramène au champ de mot de passe.
    Keys.onPressed: (e) => { if (!password.activeFocus) { password.forceActiveFocus(); password.text += e.text } }
    Component.onCompleted: password.forceActiveFocus()
}
