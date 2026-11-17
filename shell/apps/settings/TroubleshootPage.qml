import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Paramètres → Dépannage : analyse du journal et explications en langage courant.
Column {
    id: page
    spacing: Theme.space2
    signal openPage(string id)
    property bool showDetails: false
    Component.onCompleted: if (visible && !Diagnostics.lastRun.getTime()) Diagnostics.run()
    onVisibleChanged: if (visible && !Diagnostics.running && !Diagnostics.lastRun.getTime()) Diagnostics.run()

    function act(a) {
        if (a.startsWith("page:")) page.openPage(a.slice(5))
        else if (a.startsWith("run:")) Session.launch(a.slice(4))
    }

    SettingsRow {
        title: Diagnostics.running ? qsTr("Analyse en cours…")
             : !Diagnostics.lastRun.getTime() ? qsTr("Pas encore analysé")
             : Diagnostics.issues.length === 0 ? qsTr("Aucun problème détecté")
             : qsTr("%n point(s) à vérifier", "", Diagnostics.issues.length)
        description: Diagnostics.lastRun.getTime()
                     ? qsTr("Depuis le dernier démarrage · analyse à %1").arg(Qt.formatTime(Diagnostics.lastRun, "HH:mm"))
                     : qsTr("VinX lit le journal du système et explique les problèmes courants.")
        Button { text: qsTr("Analyser"); variant: Button.Secondary; enabled: !Diagnostics.running; onClicked: Diagnostics.run() }
    }

    // Tout va bien
    Row {
        visible: !Diagnostics.running && Diagnostics.lastRun.getTime() > 0 && Diagnostics.issues.length === 0
        spacing: Theme.space3; topPadding: Theme.space3; bottomPadding: Theme.space3
        Rectangle {
            width: 36; height: 36; radius: 18; color: Theme.accent
            Icon { anchors.centerIn: parent; name: "check"; color: Theme.accentText }
        }
        Label { text: qsTr("Votre système fonctionne normalement."); anchors.verticalCenter: parent.verticalCenter }
    }

    // Problèmes détectés
    Repeater {
        model: Diagnostics.issues
        delegate: Rectangle {
            id: card
            required property var modelData
            width: page.width
            height: body.height + Theme.space3 * 2
            radius: Theme.radiusMd
            color: Theme.surfaceSunken
            border.width: 1
            border.color: Theme.border
            Rectangle {   // repère de gravité, à gauche
                width: 3; radius: 1.5
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: Theme.space2 }
                color: card.modelData.severity >= 2 ? Theme.danger : Theme.warning
            }
            Column {
                id: body
                x: Theme.space5; y: Theme.space3
                width: parent.width - Theme.space5 - Theme.space3
                spacing: 4
                Label { text: card.modelData.title; font.weight: Font.DemiBold; width: parent.width; wrapMode: Text.WordWrap }
                Label { text: card.modelData.advice; level: Label.Secondary; width: parent.width; wrapMode: Text.WordWrap }
                Label {
                    visible: card.modelData.count > 1
                    text: qsTr("Survenu %n fois depuis le démarrage", "", card.modelData.count)
                    level: Label.Tertiary; font.pixelSize: Theme.fsXs
                }
                Button {
                    visible: card.modelData.action !== ""
                    text: card.modelData.actionLabel
                    variant: Button.Secondary
                    onClicked: page.act(card.modelData.action)
                }
            }
        }
    }

    SettingsRow {
        visible: Diagnostics.limited && !Diagnostics.running
        title: qsTr("Analyse complète")
        description: qsTr("Inclut les messages du système (imprimantes, Wi-Fi, disques). Mot de passe administrateur demandé.")
        Button { text: qsTr("Lancer"); variant: Button.Secondary; onClicked: Diagnostics.run(true) }
    }

    // Détail technique, pour une demande d'aide
    MenuItem {
        visible: Diagnostics.details !== ""
        width: parent.width
        iconName: "list"
        text: page.showDetails ? qsTr("Masquer le détail technique") : qsTr("Afficher le détail technique")
        onTriggered: page.showDetails = !page.showDetails
    }
    Rectangle {
        visible: page.showDetails
        width: page.width; height: 220
        radius: Theme.radiusSm
        color: Theme.surfaceSunken; border.width: 1; border.color: Theme.border
        Flickable {
            anchors { fill: parent; margins: Theme.space2 }
            clip: true
            contentHeight: raw.implicitHeight
            TextEdit {
                id: raw
                width: parent.width
                readOnly: true; selectByMouse: true
                wrapMode: TextEdit.WrapAnywhere
                text: Diagnostics.details
                color: Theme.textSecondary
                font.family: "monospace"; font.pixelSize: 11
            }
        }
    }
}
