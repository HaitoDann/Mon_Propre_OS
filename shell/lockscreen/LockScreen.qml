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
    Image {
        anchors.fill: parent
        readonly property string path: String(Preferences.value("desktop/wallpaper",
                                         "/usr/share/wallpapers/VinX-Graphite/contents/images/3840x2160.png"))
        source: Session.fileExists(path) ? "file://" + path : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: "#000000"; opacity: Theme.dark ? 0.55 : 0.35 }

    // ---------- Heure et date ----------
    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.16 }
        spacing: Theme.space2
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "HH:mm")
            color: "white"
            font.pixelSize: 96
            font.weight: Font.Light
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: { const s = root.now.toLocaleDateString(Qt.locale(), "dddd d MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
            color: "#E6FFFFFF"
            font.pixelSize: Theme.fsLg
        }
    }

    // ---------- Déverrouillage ----------
    Column {
        id: form
        visible: root.locked
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.verticalCenter; topMargin: Theme.space5 }
        spacing: Theme.space3
        width: 300

        // Pastille avec l'initiale de l'utilisateur
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 72; height: 72; radius: 36
            color: "#33FFFFFF"
            border.width: 1; border.color: "#40FFFFFF"
            Label {
                anchors.centerIn: parent
                text: (kscreenlocker_userName || "?").charAt(0).toUpperCase()
                color: "white"
                font.pixelSize: 30
                font.weight: Font.DemiBold
            }
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: kscreenlocker_userName || qsTr("Session verrouillée")
            color: "white"
            font.pixelSize: Theme.fsLg
            font.weight: Font.DemiBold
        }

        // Champ de mot de passe
        Rectangle {
            width: parent.width; height: 40
            radius: Theme.radiusMd
            color: "#26FFFFFF"
            border.width: password.activeFocus ? 2 : 1
            border.color: password.activeFocus ? "#B3FFFFFF" : "#33FFFFFF"
            opacity: authenticator.busy ? 0.6 : 1

            TextInput {
                id: password
                anchors { left: parent.left; right: go.left; leftMargin: Theme.space3; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: "white"
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
                    color: "#99FFFFFF"
                    font.pixelSize: Theme.fsLg
                }
            }
            // Bouton « valider »
            Rectangle {
                id: go
                anchors { right: parent.right; rightMargin: 5; verticalCenter: parent.verticalCenter }
                width: 30; height: 30; radius: 15
                color: password.text !== "" ? Theme.accent : "#26FFFFFF"
                Icon { anchors.centerIn: parent; name: "chevron-r"; color: "white" }
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
            color: "#FFD7D7"
            font.pixelSize: Theme.fsSm
            visible: text !== ""
        }
    }

    // ---------- Actions en bas ----------
    Row {
        visible: root.locked && root.suspendToRamSupported
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.space6 }
        spacing: Theme.space4
        Rectangle {
            width: sleepRow.implicitWidth + Theme.space4 * 2; height: 32
            radius: 16
            color: sleepMouse.containsMouse ? "#33FFFFFF" : "#1AFFFFFF"
            Row {
                id: sleepRow
                anchors.centerIn: parent
                spacing: Theme.space2
                Icon { name: "moon"; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                Label { text: qsTr("Mettre en veille"); color: "white" }
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
