import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Écran de verrouillage de VinX OS : même dessin que l'écran de connexion (ADR 0041), panneau
// latéral à gauche (heure, compte, mot de passe, veille) et fond « VinX Logo » à droite.
// Chargé par kscreenlocker depuis le paquet de shell org.vinx.lockscreen (ADR 0045). La sécurité
// reste celle de KDE : l'authentification passe par l'objet « authenticator » (PAM) et le verrouilleur
// ne se ferme que si le mot de passe est validé. En cas d'erreur de chargement, KDE affiche son écran
// de secours.
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
    readonly property string userName: kscreenlocker_userName || ""

    // Apparence de la session (clair/sombre, accent) lue directement dans les préférences : l'écran ne
    // charge pas le module du bureau (Vinx.Shell), trop lourd pour le processus de verrouillage.
    function truthy(v) { return v === true || v === "true" }
    function applyAppearance() {
        Theme.dark = truthy(Preferences.value("appearance/dark", false))
        const a = String(Preferences.value("appearance/resolvedAccent", ""))
        Theme.accentId = Theme.accents.some(e => e.id === a) ? a : Theme.accents[0].id
        Theme.highContrast = truthy(Preferences.value("accessibility/highContrast", false))
        Theme.reduceMotion = truthy(Preferences.value("accessibility/reduceMotion", false))
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // ---------- Fond : celui du bureau (« VinX Logo » à l'accent, ou l'image choisie) ----------
    Rectangle { anchors.fill: parent; color: Theme.background }
    readonly property string wallpaper: String(Preferences.value("desktop/wallpaper", ""))
    readonly property var logoMatch: /\/VinX-Logo(-Sombre)?\//.exec(wallpaper)
    LogoWallpaper {
        anchors.fill: parent
        visible: root.wallpaper === "" || root.logoMatch !== null
        dark: root.logoMatch !== null && root.logoMatch[1] !== undefined ? true : Theme.dark
    }
    Image {
        anchors.fill: parent
        visible: status === Image.Ready && root.wallpaper !== "" && root.logoMatch === null
        source: root.wallpaper !== "" && root.logoMatch === null ? "file://" + root.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(root.width, root.height)
    }

    // ---------- Panneau latéral ----------
    Rectangle {
        id: panel
        width: Math.round(Math.min(Math.max(root.width * 0.3, 380), 520))
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        color: Theme.surfaceWindow
        transform: Translate {
            x: root.locked ? 0 : -24
            Behavior on x { NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutCubic } }
        }
        opacity: root.locked ? 1 : 0
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

        Column {
            anchors { left: parent.left; right: parent.right; leftMargin: panel.pad; rightMargin: panel.pad; verticalCenter: parent.verticalCenter }
            spacing: 0

            Label { text: Qt.formatTime(root.now, "HH:mm"); color: Theme.text; font.pixelSize: 76; font.weight: Font.Light }
            Label {
                text: { const s = root.now.toLocaleDateString(Qt.locale(), "dddd d MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
                color: Theme.textSecondary; font.pixelSize: 17
            }
            Item { width: 1; height: 56 }

            // Compte verrouillé
            Item {
                width: parent.width; height: 56
                Rectangle {
                    id: avatar
                    x: 8; anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40; radius: 20
                    color: Theme.accent
                    Label { anchors.centerIn: parent; text: (root.userName || "?").charAt(0).toUpperCase(); color: Theme.accentText; font.pixelSize: 17; font.weight: Font.DemiBold }
                }
                Column {
                    anchors { left: avatar.right; leftMargin: 14; right: parent.right; verticalCenter: parent.verticalCenter }
                    Label { width: parent.width; text: root.userName || qsTr("Session verrouillée"); elide: Text.ElideRight; font.pixelSize: 16; font.weight: Font.DemiBold }
                    Label { text: qsTr("Session verrouillée"); visible: root.userName !== ""; level: Label.Tertiary; font.pixelSize: Theme.fsSm }
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
                opacity: authenticator.busy ? 0.6 : 1
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
                    enabled: !authenticator.busy
                    Accessible.name: qsTr("Mot de passe")
                    Keys.onReturnPressed: root.tryUnlock()
                    Keys.onEnterPressed: root.tryUnlock()
                    Keys.onEscapePressed: text = ""
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
                    MouseArea { anchors.fill: parent; onClicked: root.tryUnlock() }
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Déverrouiller")
                }
            }
            Item { width: 1; height: 10 }
            Label {
                width: parent.width; leftPadding: 20
                wrapMode: Text.WordWrap
                opacity: root.message !== "" ? 1 : 0
                text: root.message
                color: Theme.danger; font.pixelSize: 13
            }
        }

        // Bas du panneau : veille
        Row {
            visible: root.suspendToRamSupported
            anchors { right: parent.right; bottom: parent.bottom; rightMargin: panel.pad; bottomMargin: 36 }
            Rectangle {
                width: sleepRow.implicitWidth + 28; height: 40; radius: 20
                color: sleepMouse.containsMouse ? Theme.surfaceActive : "transparent"
                Row {
                    id: sleepRow
                    anchors.centerIn: parent
                    spacing: Theme.space2
                    Icon { name: "moon"; color: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: qsTr("Mettre en veille"); color: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: sleepMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.suspendToRam() }
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Mettre en veille")
            }
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
            shake.restart()
        }
        function onInfoMessageChanged() { if (authenticator.infoMessage) root.message = authenticator.infoMessage }
        function onErrorMessageChanged() { if (authenticator.errorMessage) root.message = authenticator.errorMessage }
        function onBusyChanged() { if (!authenticator.busy) password.forceActiveFocus() }
        // Mot de passe validé : kscreenlocker ne ferme l'écran que dans ce cas.
        function onSucceeded() { Qt.quit() }
    }

    // Toute frappe ramène au champ de mot de passe.
    Keys.onPressed: (e) => { if (!password.activeFocus) { password.forceActiveFocus(); password.text += e.text } }
    Component.onCompleted: { applyAppearance(); password.forceActiveFocus() }
}
