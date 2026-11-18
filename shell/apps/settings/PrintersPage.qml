import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Paramètres → Imprimantes : imprimantes installées, détection des imprimantes réseau (sans pilote),
// ajout en un clic, imprimante par défaut, page de test, annulation des impressions.
Column {
    id: page
    spacing: Theme.space2
    property string message: ""
    property bool ok: true
    onVisibleChanged: if (visible) { Printers.refresh(); Printers.discover() }
    Component.onCompleted: if (visible) { Printers.refresh(); Printers.discover() }
    Connections { target: Printers; function onFinished(success, msg) { page.message = msg; page.ok = success } }

    Label { visible: !Printers.available; text: qsTr("Le service d'impression (CUPS) n'est pas installé."); level: Label.Secondary }

    Label { text: qsTr("IMPRIMANTES"); level: Label.Secondary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.8; height: 24; verticalAlignment: Text.AlignBottom }
    Label { visible: Printers.available && Printers.printers.length === 0; text: qsTr("Aucune imprimante installée."); level: Label.Secondary }
    Repeater {
        model: Printers.printers
        delegate: SettingsRow {
            required property var modelData
            title: modelData.name.replace(/_/g, " ")
            description: (modelData.isDefault ? qsTr("Par défaut · ") : "")
                       + (modelData.status === "printing" ? qsTr("Impression en cours") : modelData.status === "disabled" ? qsTr("En pause") : qsTr("Prête"))
            Row {
                spacing: Theme.space2
                Button { visible: !modelData.isDefault; text: qsTr("Par défaut"); variant: Button.Ghost; onClicked: Printers.setDefault(modelData.name) }
                Button { text: qsTr("Page de test"); variant: Button.Secondary; onClicked: Printers.printTestPage(modelData.name) }
                Button { visible: modelData.status === "printing"; text: qsTr("Annuler"); variant: Button.Ghost; onClicked: Printers.cancelJobs(modelData.name) }
                Button { text: qsTr("Options"); variant: Button.Ghost; onClicked: page.optionsFor = page.optionsFor === modelData.name ? "" : modelData.name }
                Button { text: qsTr("Supprimer"); variant: Button.Ghost; enabled: !Printers.busy; onClicked: Printers.remove(modelData.name) }
            }
        }
    }
    // Options par défaut de l'imprimante choisie (papier, recto verso, couleur).
    property string optionsFor: ""
    Column {
        id: opts
        visible: page.optionsFor !== ""
        width: parent.width
        property var values: page.optionsFor ? Printers.options(page.optionsFor) : ({})
        onVisibleChanged: if (visible) values = Printers.options(page.optionsFor)
        Label { text: qsTr("Options de %1").arg(page.optionsFor.replace(/_/g, " ")); font.weight: Font.DemiBold; topPadding: Theme.space2 }
        SettingsRow {
            title: qsTr("Format du papier")
            SegmentedControl {
                model: ["A4", "Lettre US"]
                currentIndex: opts.values.media === "letter" ? 1 : 0
                onActivated: (i) => Printers.setOption(page.optionsFor, "media", i === 1 ? "Letter" : "A4")
            }
        }
        SettingsRow {
            title: qsTr("Recto verso")
            SegmentedControl {
                readonly property var values: ["one-sided", "two-sided-long-edge", "two-sided-short-edge"]
                model: [qsTr("Non"), qsTr("Bord long"), qsTr("Bord court")]
                currentIndex: Math.max(0, values.indexOf(opts.values.sides))
                onActivated: (i) => Printers.setOption(page.optionsFor, "sides", values[i])
            }
        }
        SettingsRow {
            title: qsTr("Couleur")
            SegmentedControl {
                model: [qsTr("Couleur"), qsTr("Noir et blanc")]
                currentIndex: opts.values.color === "monochrome" ? 1 : 0
                onActivated: (i) => Printers.setOption(page.optionsFor, "print-color-mode", i === 1 ? "monochrome" : "color")
            }
        }
    }

    Item { width: 1; height: Theme.space3 }
    Item {
        width: parent.width; height: 28
        Label { text: qsTr("IMPRIMANTES DÉTECTÉES SUR LE RÉSEAU"); level: Label.Secondary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.8; anchors.bottom: parent.bottom }
        Button { anchors.right: parent.right; text: Printers.searching ? qsTr("Recherche…") : qsTr("Rechercher"); variant: Button.Ghost; enabled: !Printers.searching; onClicked: Printers.discover() }
    }
    Label {
        visible: !Printers.searching && Printers.discovered.length === 0
        width: parent.width; wrapMode: Text.WordWrap
        text: qsTr("Aucune nouvelle imprimante. Vérifiez qu'elle est allumée et connectée au même réseau. Les imprimantes USB sont en général ajoutées automatiquement.")
        level: Label.Secondary
    }
    Repeater {
        model: Printers.discovered
        delegate: SettingsRow {
            required property var modelData
            title: modelData.name
            description: qsTr("Fonctionne sans pilote")
            Button { text: qsTr("Ajouter"); variant: Button.Primary; enabled: !Printers.busy; onClicked: Printers.add(modelData.name, modelData.uri) }
        }
    }

    Label {
        visible: page.message !== ""
        width: parent.width; wrapMode: Text.WordWrap; topPadding: Theme.space2
        text: page.message
        color: page.ok ? Theme.accentForeground : Theme.danger
    }
    SettingsRow {
        title: qsTr("Imprimante ancienne ou non détectée")
        description: qsTr("Ajout manuel avec choix du pilote, dans la page d'administration de l'impression (navigateur).")
        Button { text: qsTr("Ouvrir…"); variant: Button.Ghost; onClicked: Qt.openUrlExternally("http://localhost:631/admin") }
    }
}
