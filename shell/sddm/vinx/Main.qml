import QtQuick
import Vinx.Theme
import Vinx.Controls

// Écran de connexion VinX OS (SDDM, API de thème 2) — ADR 0041 : panneau latéral minimaliste à gauche
// (heure, comptes, mot de passe, alimentation) et fond « VinX Logo » dessiné en direct à droite.
// Il suit le thème global : clair/sombre et accent sont recopiés par vinx-greeter-sync dans
// theme.conf.user (clés « dark » et « accent »), lu ici via « config ».
// Objets fournis par SDDM : sddm (login, powerOff, reboot, suspend…), userModel, sessionModel,
// config (theme.conf + theme.conf.user), keyboard. Aucune logique d'authentification ici : SDDM et PAM.
Rectangle {
    id: root
    width: 1920; height: 1080
    color: Theme.background

    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string message: ""
    property date now: new Date()
    property bool shown: false

    function truthy(v) { return v === true || String(v) === "true" }
    Component.onCompleted: {
        Theme.dark = truthy(config.dark)          // thème clair par défaut (identité VinX)
        const a = String(config.accent || "")
        if (Theme.accents.some(e => e.id === a)) Theme.accentId = a
        shown = true
        password.forceActiveFocus()
    }
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
    function selectUser(i) { root.userIndex = i; password.text = ""; root.message = ""; password.forceActiveFocus() }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.message = qsTr("Mot de passe incorrect.")
            password.selectAll()
            shake.restart()
        }
    }

    // ---------- Fond : « VinX Logo » à la couleur d'accent (même composition que le bureau : le logo,
    // placé à droite du centre, reste entièrement visible à côté du panneau) ----------
    LogoWallpaper {
        id: wallpaper
        anchors.fill: parent
        dark: Theme.dark
        logoColor: Theme.logo
    }

    // ---------- Panneau latéral ----------
    Rectangle {
        id: panel
        width: Math.round(Math.min(Math.max(root.width * 0.3, 380), 520))
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        color: Theme.surfaceWindow
        // Arrivée : le panneau glisse depuis la gauche.
        transform: Translate {
            x: root.shown ? 0 : -24
            Behavior on x { NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutCubic } }
        }
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durSlow } }
        Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.border }

        readonly property int pad: 48

        // Marque
        Row {
            anchors { left: parent.left; top: parent.top; leftMargin: panel.pad; topMargin: 40 }
            spacing: 10
            Icon { name: "vinx"; width: 26; height: 19; color: Theme.accentForeground; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "VinX OS"; color: Theme.text; font.weight: Font.DemiBold; font.pixelSize: 15 }
        }

        // Contenu centré verticalement
        Column {
            id: content
            anchors { left: parent.left; right: parent.right; leftMargin: panel.pad; rightMargin: panel.pad; verticalCenter: parent.verticalCenter }
            spacing: 0

            Label { text: Qt.formatTime(root.now, "HH:mm"); color: Theme.text; font.pixelSize: 76; font.weight: Font.Light }
            Label {
                text: { const s = root.now.toLocaleDateString(Qt.locale(), "dddd d MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
                color: Theme.textSecondary; font.pixelSize: 17
            }
            Item { width: 1; height: 56 }

            // Comptes : liste si plusieurs, sinon le seul compte
            Column {
                width: parent.width
                spacing: 4
                Repeater {
                    model: root.users
                    delegate: Rectangle {
                        id: userRow
                        required property int index
                        required property var modelData
                        readonly property bool current: index === root.userIndex
                        readonly property string label: modelData ? modelData.realName : ""
                        width: parent.width; height: 56; radius: 14
                        color: root.users.length > 1 && current ? Theme.surfaceSunken
                             : userMouse.containsMouse && root.users.length > 1 ? Theme.surfaceHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        Rectangle {
                            id: avatar
                            x: 8; anchors.verticalCenter: parent.verticalCenter
                            width: 40; height: 40; radius: 20
                            color: userRow.current ? Theme.accent : Theme.surfaceActive
                            Label { anchors.centerIn: parent; text: userRow.label.charAt(0).toUpperCase(); color: userRow.current ? Theme.accentText : Theme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
                        }
                        Label {
                            anchors { left: avatar.right; leftMargin: 14; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            text: userRow.label; elide: Text.ElideRight
                            color: userRow.current ? Theme.text : Theme.textSecondary
                            font.pixelSize: 16; font.weight: userRow.current ? Font.DemiBold : Font.Normal
                        }
                        MouseArea { id: userMouse; anchors.fill: parent; hoverEnabled: true; enabled: root.users.length > 1; onClicked: root.selectUser(userRow.index) }
                        Accessible.role: Accessible.Button
                        Accessible.name: userRow.label
                    }
                }
            }
            Item { width: 1; height: 16 }

            // Mot de passe
            Rectangle {
                id: field
                width: parent.width; height: 48; radius: 24
                color: Theme.surfaceSunken
                border.width: password.activeFocus ? 2 : 1
                border.color: root.message ? Theme.danger : password.activeFocus ? Theme.accentForeground : Theme.borderStrong
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: field; property: "x"; to: -10; duration: 50 }
                    NumberAnimation { target: field; property: "x"; to: 10; duration: 70 }
                    NumberAnimation { target: field; property: "x"; to: -6; duration: 60 }
                    NumberAnimation { target: field; property: "x"; to: 0; duration: 50 }
                }
                TextInput {
                    id: password
                    anchors { left: parent.left; right: go.left; leftMargin: 20; rightMargin: 8; verticalCenter: parent.verticalCenter }
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
                Rectangle {
                    id: go
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    width: 36; height: 36; radius: 18
                    color: password.text ? Theme.accent : Theme.surfaceActive
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    Icon { anchors.centerIn: parent; name: "chevron-r"; color: password.text ? Theme.accentText : Theme.textSecondary }
                    MouseArea { anchors.fill: parent; onClicked: root.login() }
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Se connecter")
                }
            }
            Item { width: 1; height: 10 }
            Label {
                width: parent.width; leftPadding: 20
                height: 18
                opacity: root.message !== "" || keyboard.capsLock ? 1 : 0
                text: root.message || qsTr("Majuscules activées")
                color: root.message ? Theme.danger : Theme.accentForeground; font.pixelSize: 13
            }
        }

        // Bas du panneau : session (s'il y en a plusieurs) et alimentation
        Item {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: panel.pad; rightMargin: panel.pad; bottomMargin: 36 }
            height: 40
            Rectangle {
                visible: root.sessions.length > 1
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: sessionLabel.implicitWidth + 28; height: 32; radius: 16
                color: sessionMouse.containsMouse ? Theme.surfaceActive : Theme.surfaceSunken
                Label { id: sessionLabel; anchors.centerIn: parent; color: Theme.textSecondary; font.pixelSize: 13; text: root.sessions[root.sessionIndex] || "" }
                MouseArea { id: sessionMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length }
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Session : %1").arg(sessionLabel.text)
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 6
                Repeater {
                    model: [{ icon: "moon", text: qsTr("Veille"), ok: sddm.canSuspend, act: () => sddm.suspend() },
                            { icon: "restart", text: qsTr("Redémarrer"), ok: sddm.canReboot, act: () => sddm.reboot() },
                            { icon: "power", text: qsTr("Éteindre"), ok: sddm.canPowerOff, act: () => sddm.powerOff() }]
                    delegate: Rectangle {
                        required property var modelData
                        visible: modelData.ok
                        width: 40; height: 40; radius: 20
                        color: pm.containsMouse ? Theme.surfaceActive : "transparent"
                        Icon { anchors.centerIn: parent; name: modelData.icon; color: Theme.textSecondary }
                        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.act() }
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.text
                    }
                }
            }
        }
    }
}
