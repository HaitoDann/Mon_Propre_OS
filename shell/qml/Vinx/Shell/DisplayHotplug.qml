import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Branchement d'un écran : « Dupliquer, étendre, ou seulement le nouvel écran ? »
// Applique le choix avec kscreen-doctor (KDE). Affiché en tête des bulles de notification.
Surface {
    id: root
    kind: Surface.Strong
    elevation: 2
    width: 360
    height: visible ? col.height + Theme.space3 * 2 : 0
    visible: newOutput !== ""

    property string newOutput: ""     // nom de la sortie branchée (ex. HDMI-A-1)
    property string mainOutput: ""    // écran déjà utilisé (souvent l'écran intégré eDP-1)
    property int knownCount: Qt.application.screens.length

    function outputs() {
        try { return (JSON.parse(Session.capture("kscreen-doctor", ["-j"]) || "{}").outputs || []).filter(o => o.connected) }
        catch (e) { return [] }
    }
    function logicalWidth(o) { return Math.round((o.size ? o.size.width : 1920) / (o.scale || 1)) }

    // Nouvel écran : on retrouve la sortie qui vient d'apparaître.
    Connections {
        target: Qt.application
        function onScreensChanged() {
            const n = Qt.application.screens.length
            if (n > root.knownCount) {
                const list = root.outputs()
                const internal = list.find(o => /^(eDP|LVDS|DSI)/.test(o.name))
                const added = list.find(o => !/^(eDP|LVDS|DSI)/.test(o.name) && o !== internal) || list[list.length - 1]
                if (added && list.length > 1) {
                    root.newOutput = added.name
                    root.mainOutput = (internal || list.find(o => o.name !== added.name)).name
                    hide.restart()
                }
            } else if (n < root.knownCount) {
                root.newOutput = ""
            }
            root.knownCount = n
        }
    }
    Timer { id: hide; interval: 30000; onTriggered: root.newOutput = "" }

    function apply(mode) {
        const main = outputs().find(o => o.name === root.mainOutput)
        const n = "output." + root.newOutput, m = "output." + root.mainOutput
        if (mode === "extend")
            Session.run("kscreen-doctor", [n + ".enable", m + ".enable", n + ".position." + (main ? main.pos.x + logicalWidth(main) : 1920) + ",0"])
        else if (mode === "mirror") {
            // Duplication : recopie de l'écran principal (repli : même position).
            if (!Session.run("kscreen-doctor", [n + ".enable", n + ".mirror." + root.mainOutput]))
                Session.run("kscreen-doctor", [n + ".enable", n + ".position." + (main ? main.pos.x + "," + main.pos.y : "0,0")])
        } else if (mode === "only")
            Session.run("kscreen-doctor", [n + ".enable", n + ".position.0,0", n + ".priority.1", m + ".disable"])
        root.newOutput = ""
    }

    Column {
        id: col
        x: Theme.space3; y: Theme.space3
        width: parent.width - Theme.space3 * 2
        spacing: Theme.space3
        Row {
            spacing: Theme.space2
            Icon { name: "monitor"; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
            Column {
                Label { text: qsTr("Nouvel écran détecté"); font.weight: Font.DemiBold }
                Label { text: qsTr("Comment l'utiliser ?"); level: Label.Secondary; font.pixelSize: Theme.fsSm }
            }
        }
        Row {
            spacing: Theme.space2
            Button { text: qsTr("Étendre"); variant: Button.Primary; onClicked: root.apply("extend") }
            Button { text: qsTr("Dupliquer"); onClicked: root.apply("mirror") }
            Button { text: qsTr("Seulement lui"); onClicked: root.apply("only") }
        }
        Label {
            text: qsTr("Réglages détaillés : Paramètres → Écrans")
            level: Label.Tertiary; font.pixelSize: Theme.fsXs
        }
    }
}
