import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Paramètres → Pilotes : analyse des composants et installation des pilotes et micrologiciels manquants.
Column {
    id: page
    spacing: Theme.space2
    property string message: ""
    property bool ok: true
    property var chosen: ({})
    onVisibleChanged: if (visible && !Drivers.scanned && !Drivers.scanning) Drivers.scan()
    Component.onCompleted: if (visible && !Drivers.scanned && !Drivers.scanning) Drivers.scan()
    Connections {
        target: Drivers
        function onFinished(success, msg) { page.message = msg; page.ok = success }
        function onSuggestionsChanged() {}
        function onChanged() { const c = {}; for (const s of Drivers.suggestions) c[s.package] = page.chosen[s.package] !== false; page.chosen = c }
    }

    SettingsRow {
        title: Drivers.scanning ? qsTr("Analyse du matériel…")
             : Drivers.installing ? qsTr("Installation en cours…")
             : !Drivers.scanned ? qsTr("Analyse non effectuée")
             : Drivers.suggestions.length === 0 ? qsTr("Tous les pilotes nécessaires sont installés.")
             : qsTr("%n pilote(s) recommandé(s)", "", Drivers.suggestions.length)
        description: qsTr("VinX recherche les pilotes et micrologiciels Debian adaptés à vos composants.")
        Button { text: qsTr("Analyser"); variant: Button.Secondary; enabled: !Drivers.scanning && !Drivers.installing; onClicked: Drivers.scan() }
    }

    Repeater {
        model: Drivers.suggestions
        delegate: SettingsRow {
            required property var modelData
            title: modelData.package
            description: modelData.reason + (modelData.nonFree ? qsTr(" Logiciel non libre (dépôt « non-free » activé automatiquement).") : "")
            Switch {
                checked: page.chosen[modelData.package] !== false
                onToggled: (c) => { const x = Object.assign({}, page.chosen); x[modelData.package] = c; page.chosen = x }
            }
        }
    }
    Button {
        visible: Drivers.suggestions.length > 0
        text: Drivers.installing ? qsTr("Installation…") : qsTr("Installer la sélection")
        variant: Button.Primary
        enabled: !Drivers.installing && Object.keys(page.chosen).some(k => page.chosen[k])
        onClicked: Drivers.install(Object.keys(page.chosen).filter(k => page.chosen[k]))
    }
    Label {
        visible: page.message !== ""
        width: parent.width; wrapMode: Text.WordWrap
        text: page.message
        color: page.ok ? Theme.accentForeground : Theme.danger
    }

    Label { visible: Drivers.devices.length > 0; text: qsTr("COMPOSANTS"); level: Label.Secondary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.8; height: 36; verticalAlignment: Text.AlignBottom }
    Repeater {
        model: Drivers.devices
        delegate: SettingsRow {
            required property var modelData
            title: modelData.name
            description: modelData.category + " · " + modelData.vendor
        }
    }
    Label {
        width: parent.width; wrapMode: Text.WordWrap; topPadding: Theme.space2
        text: qsTr("Seuls les pilotes fournis par Debian sont proposés. Certains matériels très récents n'ont pas encore de pilote sous Linux.")
        level: Label.Tertiary; font.pixelSize: Theme.fsSm
    }
}
