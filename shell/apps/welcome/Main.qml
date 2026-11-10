import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell

// Assistant de premier démarrage : bienvenue, apparence, applications, raccourcis.
// Lancé une fois par vinx-shell (préférence welcome/done), relançable depuis le menu.
Window {
    id: win
    width: 720; height: 520
    minimumWidth: 720; minimumHeight: 520
    maximumWidth: 720; maximumHeight: 520
    visible: true
    title: qsTr("Bienvenue dans VinX OS")
    color: Theme.surfaceWindow
    AppearanceSync {}

    property int step: 0
    readonly property int steps: 4
    function finish() { Preferences.setValue("welcome/done", true); Qt.quit() }

    Item {
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: footer.top; margins: Theme.space6 }

        // 1. Bienvenue
        Column {
            visible: win.step === 0
            anchors.centerIn: parent
            spacing: Theme.space4
            Icon { name: "vinx"; width: 112; height: 80; color: Theme.logo; anchors.horizontalCenter: parent.horizontalCenter }
            Label { text: qsTr("Bienvenue dans VinX OS"); font.pixelSize: 28; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
            Label {
                width: 460; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                text: qsTr("Votre système est prêt : navigateur, bureautique et messagerie sont installés. Quelques réglages pour commencer.")
                level: Label.Secondary
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // 2. Apparence
        Column {
            visible: win.step === 1
            anchors.centerIn: parent
            spacing: Theme.space5
            Label { text: qsTr("Choisissez une apparence"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
            Row {
                spacing: Theme.space5
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: [{ dark: false, label: qsTr("Claire"), bg: "#F5F5F7", bar: "#FFFFFF", fg: "#1D1D1F" },
                            { dark: true, label: qsTr("Sombre"), bg: "#141517", bar: "#1C1D20", fg: "#ECECEE" }]
                    Column {
                        required property var modelData
                        spacing: Theme.space2
                        Rectangle {
                            width: 220; height: 140; radius: Theme.radiusLg
                            color: modelData.bg
                            border.width: Theme.dark === modelData.dark ? 2 : 1
                            border.color: Theme.dark === modelData.dark ? Theme.accentForeground : Theme.border
                            Rectangle { x: 1; y: 1; width: parent.width - 2; height: 14; radius: Theme.radiusLg; color: modelData.bar }
                            Rectangle { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 10 } width: 110; height: 18; radius: 6; color: modelData.bar }
                            Rectangle { x: 30; y: 34; width: 120; height: 70; radius: 6; color: modelData.bar; border.width: 1; border.color: "#1A000000" }
                            MouseArea { anchors.fill: parent; onClicked: Preferences.setValue("appearance/dark", parent.parent.modelData.dark) }
                        }
                        Label { text: modelData.label; anchors.horizontalCenter: parent.horizontalCenter; font.weight: Theme.dark === modelData.dark ? Font.DemiBold : Font.Normal }
                    }
                }
            }
        }

        // 3. Applications
        Column {
            visible: win.step === 2
            anchors.centerIn: parent
            spacing: Theme.space4
            AppIcon { size: 64; iconName: "bag"; tint: "#5B65C9"; anchors.horizontalCenter: parent.horizontalCenter }
            Label { text: qsTr("Ajoutez ce dont vous avez besoin"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
            Label {
                width: 460; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                text: qsTr("Le Store propose des packs prêts à l'emploi : développement, graphisme, multimédia, jeux, communication.")
                level: Label.Secondary
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Button { text: qsTr("Ouvrir le Store"); anchors.horizontalCenter: parent.horizontalCenter; onClicked: Session.launch("vinx-store") }
        }

        // 4. Raccourcis
        Column {
            visible: win.step === 3
            anchors.centerIn: parent
            spacing: Theme.space4
            Label { text: qsTr("Les raccourcis essentiels"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
            Column {
                spacing: Theme.space3
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: [[qsTr("Méta"), qsTr("Rechercher une application, un fichier, un réglage")],
                            [qsTr("Méta + W"), qsTr("Vue d'ensemble des fenêtres et des bureaux")],
                            [qsTr("Méta + ← / →"), qsTr("Placer la fenêtre sur une moitié d'écran")],
                            [qsTr("Méta + ↑"), qsTr("Agrandir la fenêtre")],
                            [qsTr("Ctrl + Méta + ← / →"), qsTr("Bureau précédent / suivant")]]
                    Row {
                        required property var modelData
                        spacing: Theme.space4
                        Rectangle {
                            width: 160; height: 28; radius: Theme.radiusSm
                            color: Theme.surfaceSunken
                            border.width: 1; border.color: Theme.borderStrong
                            Label { anchors.centerIn: parent; text: modelData[0]; font.weight: Font.Medium; font.pixelSize: Theme.fsSm }
                        }
                        Label { text: modelData[1]; height: 28; width: 330 }
                    }
                }
            }
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
                    width: index === win.step ? 18 : 6; height: 6; radius: 3
                    color: index === win.step ? Theme.text : Theme.textTertiary
                    Behavior on width { NumberAnimation { duration: Theme.durNormal } }
                }
            }
        }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: Theme.space2
            Button { text: qsTr("Passer"); variant: Button.Ghost; visible: win.step < win.steps - 1; onClicked: win.finish() }
            Button { text: qsTr("Précédent"); visible: win.step > 0; onClicked: win.step-- }
            Button {
                text: win.step === win.steps - 1 ? qsTr("Commencer") : qsTr("Suivant")
                variant: Button.Primary
                onClicked: win.step === win.steps - 1 ? win.finish() : win.step++
            }
        }
    }
}
