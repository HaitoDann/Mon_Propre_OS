import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell

// Assistant de premier démarrage (ADR 0030) : quatre étapes simples — bienvenue, Internet,
// apparence, gestes essentiels. Aucun réglage technique : les instantanés sont activés
// automatiquement et LibreOffice enregistre au format Microsoft Office par défaut.
// Lancé une fois par vinx-shell (préférence welcome/done), relançable depuis la recherche.
Window {
    id: win
    width: 760; height: 560
    minimumWidth: 760; minimumHeight: 560
    maximumWidth: 760; maximumHeight: 560
    visible: true
    title: qsTr("Bienvenue dans VinX OS")
    color: Theme.surfaceWindow
    AppearanceSync {}

    property string startStep: ""
    property int step: Math.max(0, Math.min(3, parseInt(startStep) || 0))
    readonly property int steps: 4
    function finish() { Preferences.setValue("welcome/done", true); Qt.quit() }
    function pref(k, d) { Preferences.revision; return Preferences.value(k, d) }

    Item {
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: footer.top; margins: Theme.space6 }

        // 1. Bienvenue
        Column {
            visible: win.step === 0
            anchors.centerIn: parent
            spacing: Theme.space4
            Icon { name: "vinx"; width: 120; height: 86; color: Theme.logo; anchors.horizontalCenter: parent.horizontalCenter }
            Label { text: qsTr("Bienvenue dans VinX OS"); font.pixelSize: 28; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
            Label {
                width: 480; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                text: qsTr("Votre ordinateur est prêt : navigateur, bureautique et messagerie sont installés. Trois petits réglages pour commencer.")
                level: Label.Secondary
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // 2. Internet
        Column {
            visible: win.step === 1
            anchors.centerIn: parent
            width: 440
            spacing: Theme.space3
            Label { text: qsTr("Connexion à Internet"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
            Label {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                level: Label.Secondary
                text: !Network.available ? qsTr("Le réseau n'est pas disponible pour le moment. Vous pourrez vous connecter plus tard depuis la barre du haut.")
                    : Network.connected ? qsTr("Vous êtes connecté : %1.").arg(Network.connectionName)
                    : qsTr("Choisissez un réseau Wi-Fi ou branchez un câble.")
            }
            Loader {
                active: win.step === 1 && Wifi.available
                width: parent.width
                sourceComponent: WifiNetworks { width: parent ? parent.width : 440; listHeight: 250 }
            }
        }

        // 3. Apparence
        Column {
            visible: win.step === 2
            anchors.centerIn: parent
            spacing: Theme.space5
            Label { text: qsTr("Votre apparence"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
            Row {
                spacing: Theme.space5
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: [{ dark: false, label: qsTr("Clair") }, { dark: true, label: qsTr("Sombre") }]
                    Column {
                        id: themeCard
                        required property var modelData
                        spacing: Theme.space2
                        Rectangle {
                            width: 200; height: 120; radius: Theme.radiusMd
                            border.width: 2
                            border.color: Theme.dark === themeCard.modelData.dark ? Theme.accentForeground : Theme.border
                            clip: true
                            LogoWallpaper { anchors { fill: parent; margins: 2 } dark: themeCard.modelData.dark }
                            Rectangle { x: 2; y: 2; width: parent.width - 4; height: 12; color: themeCard.modelData.dark ? "#1A1C1B" : "#F8F7F4"; opacity: 0.95 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Preferences.setValue("appearance/dark", themeCard.modelData.dark) }
                        }
                        Label { text: themeCard.modelData.label; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }
            }
            Label { text: qsTr("Couleur d'accent"); level: Label.Secondary; anchors.horizontalCenter: parent.horizontalCenter }
            Row {
                spacing: Theme.space2
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: Theme.accents
                    Rectangle {
                        required property var modelData
                        readonly property bool current: Theme.accentId === modelData.id && String(win.pref("appearance/accent", "")) !== "auto"
                        width: 30; height: 30; radius: 15
                        color: modelData.fill
                        Rectangle { anchors.centerIn: parent; width: 38; height: 38; radius: 19; color: "transparent"; border.width: 2; border.color: Theme.text; visible: parent.current }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Preferences.setValue("appearance/accent", parent.modelData.id) }
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: modelData.name
                    }
                }
            }
        }

        // 4. Gestes essentiels
        Column {
            visible: win.step === 3
            anchors.centerIn: parent
            spacing: Theme.space4
            Label { text: qsTr("Les gestes essentiels"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
            Column {
                spacing: Theme.space2
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: [[qsTr("Méta"), qsTr("Rechercher une application, un fichier, un réglage")],
                            [qsTr("Méta + W"), qsTr("Voir toutes les fenêtres")],
                            [qsTr("Méta + ← / →"), qsTr("Placer une fenêtre sur une moitié d'écran")],
                            [qsTr("Clic sur une icône du dock"), qsTr("Ouvrir, ramener ou réduire")]]
                    Row {
                        required property var modelData
                        spacing: Theme.space3
                        Rectangle {
                            width: 190; height: 28; radius: Theme.radiusSm
                            color: Theme.surfaceSunken
                            border.width: 1; border.color: Theme.borderStrong
                            Label { anchors.centerIn: parent; text: modelData[0]; font.weight: Font.Medium; font.pixelSize: Theme.fsSm }
                        }
                        Label { text: modelData[1]; height: 28; verticalAlignment: Text.AlignVCenter; width: 360 }
                    }
                }
            }
            Label {
                width: 520; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                level: Label.Secondary
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Besoin d'un logiciel ? Le Store en propose des centaines, en un clic.")
            }
            Button { text: qsTr("Ouvrir le Store"); anchors.horizontalCenter: parent.horizontalCenter; onClicked: Session.launch("vinx-store") }
        }
    }

    // ---------- Pied : progression et navigation ----------
    Item {
        id: footer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.space5 }
        height: 32
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Repeater {
                model: win.steps
                Rectangle {
                    required property int index
                    width: 28; height: 4; radius: 2
                    color: index <= win.step ? Theme.accent : Theme.border
                }
            }
        }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: Theme.space2
            Button { text: qsTr("Passer"); variant: Button.Ghost; visible: win.step < win.steps - 1; onClicked: win.finish() }
            Button { text: qsTr("Précédent"); visible: win.step > 0; onClicked: win.step-- }
            Button {
                objectName: "nextButton"
                text: win.step === win.steps - 1 ? qsTr("Commencer") : qsTr("Suivant")
                variant: Button.Primary
                onClicked: win.step === win.steps - 1 ? win.finish() : win.step++
            }
        }
    }
}
