import QtQuick
import Vinx.Theme
import Vinx.Controls

// Écran de connexion VinX OS (SDDM, API de thème 2) : style Biseau.
// Objets fournis par SDDM : sddm (login, powerOff, reboot, suspend…), userModel, sessionModel,
// config (theme.conf), keyboard. Aucune logique d'authentification ici : SDDM et PAM s'en chargent.
Rectangle {
    id: root
    width: 1920; height: 1080
    color: Theme.background

    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string message: ""
    property date now: new Date()
    property bool shown: false
    // Identité VinX : thème clair (fond « VinX Logo »), comme le bureau par défaut.
    Component.onCompleted: { Theme.dark = false; shown = true; password.forceActiveFocus() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // Comptes et sessions lus via les rôles des modèles SDDM (« name », « realName »).
    property var users: []
    property var sessions: []
    Repeater {
        model: userModel
        delegate: Item {
            required property int index
            required property string name
            required property string realName
            Component.onCompleted: { const u = root.users.slice(); u[index] = { name: name, realName: realName || name }; root.users = u }
        }
    }
    Repeater {
        model: sessionModel
        delegate: Item {
            required property int index
            required property string name
            Component.onCompleted: { const s = root.sessions.slice(); s[index] = name; root.sessions = s }
        }
    }
    readonly property string userName: users[userIndex] ? users[userIndex].name : ""
    readonly property string realName: users[userIndex] ? users[userIndex].realName : ""

    function login() {
        if (!password.text) return
        root.message = ""
        sddm.login(root.userName, password.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.message = qsTr("Mot de passe incorrect.")
            password.selectAll()
            shake.restart()
        }
    }

    // ---------- Fond ----------
    Image {
        anchors.fill: parent
        source: config.background ? "file://" + config.background : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: Theme.background; opacity: 0.25 }

    // ---------- Marque ----------
    Row {
        anchors { left: parent.left; top: parent.top; margins: 32 }
        spacing: 10
        Icon { name: "vinx"; width: 26; height: 19; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
        Label { text: "VinX OS"; color: Theme.text; font.weight: Font.DemiBold; font.pixelSize: 15 }
    }

    // ---------- Heure ----------
    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.14 }
        spacing: 4
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(root.now, "HH:mm"); color: Theme.text; font.pixelSize: 88; font.weight: Font.Light }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: { const s = root.now.toLocaleDateString(Qt.locale(), "dddd d MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
            color: Theme.textSecondary; font.pixelSize: 17
        }
    }

    // ---------- Carte de connexion (animation signature : arrivée en diagonale) ----------
    Surface {
        id: card
        kind: Surface.Strong
        elevation: 2
        radius: 18
        width: 360
        height: form.height + 56
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.verticalCenter; topMargin: -20 }
        opacity: root.shown ? 1 : 0
        transform: Translate { id: slide; x: root.shown ? 0 : 18; y: root.shown ? 0 : -18
            Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } } }
        Behavior on opacity { NumberAnimation { duration: 320 } }
        edgeProgress: root.shown ? 1 : 0
        Behavior on edgeProgress { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -10; duration: 50 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 10; duration: 70 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -6; duration: 60 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
        }

        Column {
            id: form
            x: 28; y: 28
            width: parent.width - 56
            spacing: 14

            // Choix de l'utilisateur (plusieurs comptes)
            Row {
                visible: root.users.length > 1
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Repeater {
                    model: root.users
                    delegate: Bevel {
                        required property int index
                        required property var modelData
                        readonly property string realName: modelData ? modelData.realName : ""
                        readonly property string name: modelData ? modelData.name : ""
                        width: 44; height: 44; cut: 10
                        color: index === root.userIndex ? Theme.accent : Theme.surfaceActive
                        Label { anchors.centerIn: parent; text: (realName || name).charAt(0).toUpperCase(); color: index === root.userIndex ? Theme.accentText : Theme.text; font.weight: Font.DemiBold; font.pixelSize: 17 }
                        MouseArea { anchors.fill: parent; onClicked: { root.userIndex = index; password.forceActiveFocus() } }
                    }
                }
            }
            // Utilisateur sélectionné
            Bevel {
                visible: root.users.length <= 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: 64; height: 64; cut: 14
                color: Theme.accent
                Label { anchors.centerIn: parent; text: root.realName.charAt(0).toUpperCase(); color: Theme.accentText; font.pixelSize: 26; font.weight: Font.DemiBold }
            }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: root.realName; color: Theme.text; font.pixelSize: 17; font.weight: Font.DemiBold }

            // Mot de passe
            Bevel {
                width: parent.width; height: 42; cut: 10
                color: Theme.surfaceSunken
                borderWidth: password.activeFocus ? 2 : 1
                borderColor: password.activeFocus ? Theme.accentForeground : Theme.borderStrong
                TextInput {
                    id: password
                    anchors { left: parent.left; right: go.left; leftMargin: 14; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    color: Theme.text; selectionColor: Theme.accent; selectedTextColor: Theme.accentText
                    font.family: Theme.fontFamily; font.pixelSize: 15
                    clip: true; focus: true
                    Accessible.name: qsTr("Mot de passe")
                    Keys.onReturnPressed: root.login()
                    Keys.onEnterPressed: root.login()
                    onTextChanged: root.message = ""
                    Label { visible: !password.text; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Mot de passe"); color: Theme.textTertiary; font.pixelSize: 15 }
                }
                Bevel {
                    id: go
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    width: 32; height: 30; cut: 8
                    color: password.text ? Theme.accent : Theme.surfaceSunken
                    Icon { anchors.centerIn: parent; name: "chevron-r"; color: password.text ? Theme.accentText : Theme.text }
                    MouseArea { anchors.fill: parent; onClicked: root.login() }
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Se connecter")
                }
            }
            Label {
                visible: root.message !== "" || keyboard.capsLock
                width: parent.width; horizontalAlignment: Text.AlignHCenter
                text: root.message || qsTr("Majuscules activées")
                color: root.message ? Theme.danger : Theme.accentForeground; font.pixelSize: 12
            }
        }
    }

    // ---------- Session et alimentation ----------
    Row {
        anchors { left: parent.left; bottom: parent.bottom; margins: 28 }
        spacing: 8
        visible: root.sessions.length > 1
        Label { text: qsTr("Session :"); color: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }
        Bevel {
            width: sessionLabel.implicitWidth + 28; height: 32; cut: 8
            color: sessionMouse.containsMouse ? Theme.surfaceActive : Theme.surfaceGlassStrong
            Label {
                id: sessionLabel; anchors.centerIn: parent; color: Theme.text
                text: root.sessions[root.sessionIndex] || ""
            }
            MouseArea { id: sessionMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length }
        }
    }
    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 28 }
        spacing: 8
        Repeater {
            model: [{ icon: "moon", text: qsTr("Veille"), ok: sddm.canSuspend, act: () => sddm.suspend() },
                    { icon: "restart", text: qsTr("Redémarrer"), ok: sddm.canReboot, act: () => sddm.reboot() },
                    { icon: "power", text: qsTr("Éteindre"), ok: sddm.canPowerOff, act: () => sddm.powerOff() }]
            delegate: Bevel {
                required property var modelData
                visible: modelData.ok
                width: 40; height: 40; cut: 10
                color: pm.containsMouse ? Theme.surfaceActive : Theme.surfaceGlassStrong
                Icon { anchors.centerIn: parent; name: modelData.icon; color: Theme.text }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.act() }
                Accessible.role: Accessible.Button
                Accessible.name: modelData.text
            }
        }
    }
}
