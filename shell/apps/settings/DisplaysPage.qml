import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Paramètres → Écrans : disposition par glisser-déposer, écran principal, définition, échelle,
// activation. S'appuie sur kscreen-doctor (KDE) ; les changements s'appliquent immédiatement.
Column {
    id: page
    spacing: Theme.space3
    property var outputs: []
    property string selected: ""
    readonly property var current: outputs.find(o => o.name === selected) || outputs[0] || null

    function load() {
        try { outputs = (JSON.parse(Session.capture("kscreen-doctor", ["-j"]) || "{}").outputs || []).filter(o => o.connected) }
        catch (e) { outputs = [] }
        if (!outputs.find(o => o.name === selected) && outputs.length) selected = (outputs.find(o => o.priority === 1) || outputs[0]).name
    }
    function apply(args) { Session.run("kscreen-doctor", args); reload.restart() }
    function lw(o) { return Math.round((o.size ? o.size.width : 1920) / (o.scale || 1)) }
    function lh(o) { return Math.round((o.size ? o.size.height : 1080) / (o.scale || 1)) }
    function label(o) { return o.name.startsWith("eDP") || o.name.startsWith("LVDS") ? qsTr("Écran intégré") : o.name }
    Timer { id: reload; interval: 900; onTriggered: page.load() }
    onVisibleChanged: if (visible) load()
    Component.onCompleted: load()

    Label { visible: page.outputs.length === 0; text: qsTr("Réglage des écrans indisponible ici."); level: Label.Secondary }

    // ---------- Disposition ----------
    Rectangle {
        id: canvas
        visible: page.outputs.length > 0
        width: parent.width; height: 220
        radius: Theme.radiusMd
        color: Theme.surfaceSunken
        border.width: 1; border.color: Theme.border
        // Échelle : tous les écrans actifs tiennent dans le cadre.
        readonly property var active: page.outputs.filter(o => o.enabled)
        readonly property real minX: Math.min.apply(null, active.map(o => o.pos.x).concat([0]))
        readonly property real minY: Math.min.apply(null, active.map(o => o.pos.y).concat([0]))
        readonly property real spanW: Math.max.apply(null, active.map(o => o.pos.x + page.lw(o)).concat([1])) - minX
        readonly property real spanH: Math.max.apply(null, active.map(o => o.pos.y + page.lh(o)).concat([1])) - minY
        readonly property real k: Math.min((width - 60) / spanW, (height - 50) / spanH)
        readonly property real ox: (width - spanW * k) / 2
        readonly property real oy: (height - spanH * k) / 2

        Repeater {
            model: canvas.active
            delegate: Rectangle {
                id: scr
                required property var modelData
                readonly property bool sel: modelData.name === page.selected
                x: canvas.ox + (modelData.pos.x - canvas.minX) * canvas.k
                y: canvas.oy + (modelData.pos.y - canvas.minY) * canvas.k
                width: page.lw(modelData) * canvas.k; height: page.lh(modelData) * canvas.k
                radius: 6
                color: sel ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surfaceGlassStrong
                border.width: sel ? 2 : 1
                border.color: sel ? Theme.accentForeground : Theme.borderStrong
                Column {
                    anchors.centerIn: parent
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: page.label(scr.modelData); font.weight: Font.DemiBold; font.pixelSize: Theme.fsSm }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; visible: scr.modelData.priority === 1; text: qsTr("Principal"); level: Label.Secondary; font.pixelSize: Theme.fsXs }
                }
                // Glisser pour placer l'écran ; il s'accroche au bord le plus proche d'un autre écran.
                MouseArea {
                    anchors.fill: parent
                    drag.target: page.outputs.length > 1 ? scr : null
                    onPressed: page.selected = scr.modelData.name
                    onReleased: {
                        if (page.outputs.length < 2) return
                        let nx = Math.round((scr.x - canvas.ox) / canvas.k + canvas.minX)
                        let ny = Math.round((scr.y - canvas.oy) / canvas.k + canvas.minY)
                        const w = page.lw(scr.modelData), h = page.lh(scr.modelData)
                        let best = null, bestD = 1e9
                        for (const o of canvas.active) {
                            if (o.name === scr.modelData.name) continue
                            const cands = [[o.pos.x + page.lw(o), ny], [o.pos.x - w, ny], [nx, o.pos.y + page.lh(o)], [nx, o.pos.y - h]]
                            for (const c of cands) {
                                const d = Math.abs(c[0] - nx) + Math.abs(c[1] - ny)
                                if (d < bestD) { bestD = d; best = c }
                            }
                        }
                        if (best) { nx = best[0]; ny = best[1] }
                        // Aligne les hauts (ou les gauches) quand c'est presque le cas.
                        for (const o of canvas.active) {
                            if (o.name === scr.modelData.name) continue
                            if (Math.abs(ny - o.pos.y) < 120) ny = o.pos.y
                            if (Math.abs(nx - o.pos.x) < 120) nx = o.pos.x
                        }
                        page.apply(["output." + scr.modelData.name + ".position." + nx + "," + ny])
                    }
                }
            }
        }
        Label {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 8 }
            visible: page.outputs.length > 1
            text: qsTr("Faites glisser les écrans pour reproduire leur disposition sur votre bureau.")
            level: Label.Tertiary; font.pixelSize: Theme.fsXs
        }
    }

    // ---------- Réglages de l'écran sélectionné ----------
    Column {
        visible: page.current !== null
        width: parent.width
        Label { text: page.current ? page.label(page.current).toUpperCase() : ""; level: Label.Secondary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.8; height: 28; verticalAlignment: Text.AlignBottom }
        SettingsRow {
            visible: page.outputs.length > 1
            title: qsTr("Utiliser cet écran")
            Switch {
                checked: page.current ? page.current.enabled : false
                enabled: page.current && (!page.current.enabled || page.outputs.filter(o => o.enabled).length > 1)
                onToggled: (c) => page.apply(["output." + page.current.name + (c ? ".enable" : ".disable")])
            }
        }
        SettingsRow {
            visible: page.outputs.length > 1 && page.current && page.current.enabled
            title: qsTr("Écran principal")
            description: qsTr("Accueille la barre, le dock et les notifications.")
            Button {
                text: page.current && page.current.priority === 1 ? qsTr("Principal") : qsTr("Définir comme principal")
                variant: page.current && page.current.priority === 1 ? Button.Ghost : Button.Secondary
                enabled: page.current && page.current.priority !== 1
                onClicked: page.apply(["output." + page.current.name + ".priority.1"])
            }
        }
        SettingsRow {
            visible: page.outputs.length > 1
            title: qsTr("Dupliquer les écrans")
            description: qsTr("Le même contenu sur tous les écrans (présentations).")
            Button {
                text: qsTr("Dupliquer")
                onClicked: {
                    const main = page.outputs.find(o => o.priority === 1) || page.outputs[0]
                    for (const o of page.outputs) if (o.name !== main.name) {
                        if (!Session.run("kscreen-doctor", ["output." + o.name + ".enable", "output." + o.name + ".mirror." + main.name]))
                            Session.run("kscreen-doctor", ["output." + o.name + ".enable", "output." + o.name + ".position." + main.pos.x + "," + main.pos.y])
                    }
                    reload.restart()
                }
            }
        }
        SettingsRow {
            visible: page.current && page.current.enabled
            title: qsTr("Définition")
            description: {
                const c = page.current
                const m = c ? (c.modes || []).find(x => x.id === c.currentModeId) : null
                return m ? qsTr("%1 × %2 à %3 Hz").arg(m.size.width).arg(m.size.height).arg(Math.round(m.refreshRate)) : ""
            }
            Button { text: modes.visible ? qsTr("Fermer") : qsTr("Changer…"); variant: Button.Secondary; onClicked: modes.visible = !modes.visible }
        }
        Flow {
            id: modes
            visible: false
            width: parent.width; spacing: Theme.space2; bottomPadding: Theme.space2
            Repeater {
                model: {
                    const c = page.current
                    if (!c) return []
                    const best = {}
                    for (const m of c.modes || []) {
                        const k = m.size.width + "x" + m.size.height
                        if (!best[k] || m.refreshRate > best[k].refreshRate) best[k] = m
                    }
                    return Object.values(best).sort((a, b) => b.size.width * b.size.height - a.size.width * a.size.height)
                }
                delegate: Button {
                    required property var modelData
                    readonly property var cur: (page.current.modes || []).find(x => x.id === page.current.currentModeId)
                    text: modelData.size.width + " × " + modelData.size.height
                    variant: cur && cur.size.width === modelData.size.width && cur.size.height === modelData.size.height ? Button.Primary : Button.Secondary
                    onClicked: { page.apply(["output." + page.current.name + ".mode." + modelData.id]); modes.visible = false }
                }
            }
        }
        SettingsRow {
            visible: page.current && page.current.enabled
            title: qsTr("Taille du texte et des éléments")
            SegmentedControl {
                readonly property var scales: [1, 1.25, 1.5, 2]
                model: ["100 %", "125 %", "150 %", "200 %"]
                currentIndex: page.current ? Math.max(0, scales.indexOf(page.current.scale || 1)) : 0
                onActivated: (i) => page.apply(["output." + page.current.name + ".scale." + scales[i]])
            }
        }
        SettingsRow {
            title: qsTr("Fréquence, orientation, couleurs")
            Button { text: qsTr("Avancé…"); variant: Button.Ghost; onClicked: Session.launch("systemsettings", ["kcm_kscreen"]) }
        }
    }
}
