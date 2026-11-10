import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import "AppStyle.js" as AppStyle
import "Calc.js" as Calc

// Recherche globale : calcul, applications, réglages, fichiers, web. Navigation au clavier.
Column {
    id: search
    width: 600
    spacing: Theme.space2

    property var apps: []
    property var items: []          // résultats aplatis : { kind, title, subtitle, glyph, appId, run }
    property int selected: 0
    signal done()

    function reset() {
        field.text = ""
        apps = Applications.all()
        refresh()
        field.forceActiveFocus()
    }

    function fold(s) { return String(s).normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase() }

    function actions() {
        return [
            { title: Theme.dark ? qsTr("Passer en apparence claire") : qsTr("Passer en apparence sombre"), glyph: Theme.dark ? "sun" : "moon",
              keys: "theme apparence sombre clair mode", run: () => Preferences.setValue("appearance/dark", !Theme.dark) },
            { title: Notifications.doNotDisturb ? qsTr("Désactiver Ne pas déranger") : qsTr("Activer Ne pas déranger"), glyph: "bell-off",
              keys: "ne pas deranger notifications concentration", run: () => Preferences.setValue("notifications/dnd", !Notifications.doNotDisturb) },
            { title: Network.wirelessEnabled ? qsTr("Désactiver le Wi-Fi") : qsTr("Activer le Wi-Fi"), glyph: "wifi",
              keys: "wifi reseau internet sans fil", available: Network.available, run: () => Network.wirelessEnabled = !Network.wirelessEnabled },
            { title: Bluetooth.powered ? qsTr("Désactiver le Bluetooth") : qsTr("Activer le Bluetooth"), glyph: "bluetooth",
              keys: "bluetooth", available: Bluetooth.available, run: () => Bluetooth.powered = !Bluetooth.powered },
            { title: qsTr("Vue d'ensemble des fenêtres"), glyph: "grid", keys: "vue ensemble expose fenetres bureaux espaces",
              run: () => Session.invokeKWinShortcut("Overview") },
            { title: qsTr("Fond d'écran"), glyph: "image", keys: "fond ecran wallpaper apparence", run: () => Session.launch("vinx-settings", ["--page", "wallpaper"]) },
            { title: qsTr("Paramètres"), glyph: "sliders", keys: "parametres reglages preferences", run: () => Session.launch("vinx-settings") },
            { title: qsTr("Store"), glyph: "bag", keys: "store applications installer logiciels packs", run: () => Session.launch("vinx-store") },
            { title: qsTr("Verrouiller l'écran"), glyph: "lock", keys: "verrouiller ecran session", run: () => Session.lock() }
        ]
    }

    function refresh() {
        const q = fold(field.text.trim())
        const out = []
        if (q !== "") {
            const v = Calc.evaluate(field.text)
            if (v !== null)
                out.push({ kind: qsTr("Calcul"), title: "= " + Calc.format(v), subtitle: qsTr("Entrée pour copier le résultat"), glyph: "equals",
                           run: () => { clipboard.text = String(v); clipboard.selectAll(); clipboard.copy() } })
            const ranked = []
            for (const a of apps) {
                const n = fold(a.name)
                const score = n.startsWith(q) ? 3 : n.includes(q) ? 2 : fold(a.genericName + " " + a.keywords + " " + a.id).includes(q) ? 1 : 0
                if (score) ranked.push({ a: a, score: score })
            }
            ranked.sort((x, y) => y.score - x.score)
            for (const r of ranked.slice(0, 6))
                out.push({ kind: qsTr("Applications"), title: r.a.name, subtitle: r.a.genericName, appId: r.a.id, run: () => Applications.launch(r.a.id) })
            for (const act of actions())
                if (act.available !== false && (fold(act.title).includes(q) || act.keys.includes(q)))
                    out.push({ kind: qsTr("Réglages"), title: act.title, glyph: act.glyph, run: act.run })
            for (const f of FileSearch.search(field.text, 6))
                out.push({ kind: qsTr("Fichiers"), title: f.name, subtitle: f.folder, glyph: "doc", run: () => FileSearch.open(f.path) })
            out.push({ kind: qsTr("Web"), title: qsTr("Rechercher « %1 » sur le web").arg(field.text.trim()), glyph: "globe",
                       run: () => FileSearch.openUrl("https://duckduckgo.com/?q=" + encodeURIComponent(field.text.trim())) })
        } else {
            // Sans saisie : les applications épinglées, pour un accès immédiat.
            for (const id of AppStyle.asList(Preferences.value("dock/pinned"), AppStyle.defaultPinned)) {
                const a = apps.find(x => x.id === id)
                if (a) out.push({ kind: qsTr("Applications"), title: a.name, subtitle: a.genericName, appId: a.id, run: () => Applications.launch(a.id) })
            }
        }
        items = out
        selected = 0
    }

    function run(i) {
        const it = items[i]
        if (!it) return
        done()
        it.run()
    }

    TextEdit { id: clipboard; visible: false }

    // ---------- Champ ----------
    Rectangle {
        width: parent.width; height: 48
        radius: Theme.radiusMd
        color: Theme.surfaceHover
        Icon { id: lens; name: "search"; width: 20; height: 20; color: Theme.textSecondary; anchors { left: parent.left; leftMargin: Theme.space3; verticalCenter: parent.verticalCenter } }
        TextInput {
            id: field
            anchors { left: lens.right; leftMargin: Theme.space3; right: parent.right; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            font.family: Theme.fontFamily
            font.pixelSize: 18
            color: Theme.text
            selectionColor: Theme.accent
            clip: true
            onTextChanged: search.refresh()
            Keys.onDownPressed: search.selected = Math.min(search.items.length - 1, search.selected + 1)
            Keys.onUpPressed: search.selected = Math.max(0, search.selected - 1)
            Keys.onReturnPressed: search.run(search.selected)
            Keys.onEnterPressed: search.run(search.selected)
            Keys.onEscapePressed: search.done()
            Label {
                visible: field.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Rechercher des applications, fichiers, réglages…")
                level: Label.Tertiary
                font.pixelSize: 18
            }
        }
    }

    // ---------- Résultats ----------
    ListView {
        id: list
        width: parent.width
        height: Math.min(contentHeight, 420)
        clip: true
        model: search.items
        currentIndex: search.selected
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
        delegate: Item {
            id: row
            required property int index
            required property var modelData
            readonly property var style: modelData.appId ? AppStyle.forApp(modelData.appId) : null
            // En-tête de section au début de chaque groupe (Applications, Réglages…).
            readonly property bool firstOfKind: index === 0 || search.items[index - 1].kind !== modelData.kind
            width: ListView.view.width
            height: 44 + (firstOfKind ? 26 : 0)
            Label {
                visible: row.firstOfKind
                text: row.modelData.kind.toUpperCase()
                level: Label.Tertiary
                font.pixelSize: Theme.fsXs
                font.weight: Font.DemiBold
                font.letterSpacing: 0.5
                height: 26
                leftPadding: Theme.space2
                verticalAlignment: Text.AlignBottom
                bottomPadding: 4
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 44
                radius: Theme.radiusMd
                color: row.index === search.selected ? Theme.surfaceActive : mouse.containsMouse ? Theme.surfaceHover : "transparent"
            }
            Row {
                height: 44
                anchors { left: parent.left; leftMargin: Theme.space2; bottom: parent.bottom }
                spacing: Theme.space3
                Item {
                    width: 30; height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    AppIcon { anchors.fill: parent; size: 30; visible: row.style !== null; iconName: row.style ? row.style.glyph : ""; tint: row.style ? row.style.tint : "#5F6270" }
                    Image {
                        anchors.fill: parent
                        visible: row.style === null && !!row.modelData.appId && status === Image.Ready
                        source: row.style === null && row.modelData.appId ? "image://theme/" + row.modelData.appId : ""
                        sourceSize: Qt.size(60, 60)
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusSm
                        visible: !row.modelData.appId
                        color: Theme.surfaceActive
                        Icon { anchors.centerIn: parent; name: row.modelData.glyph || "search"; color: Theme.text }
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: row.modelData.title; font.weight: Font.Medium; width: 480 }
                    Label { visible: !!row.modelData.subtitle; text: row.modelData.subtitle || ""; level: Label.Secondary; font.pixelSize: Theme.fsSm; width: 480 }
                }
            }
            MouseArea { id: mouse; anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 44; hoverEnabled: true; onClicked: search.run(row.index) }
        }
    }
    Label {
        visible: search.items.length === 0
        width: parent.width; height: 40
        horizontalAlignment: Text.AlignHCenter
        text: qsTr("Aucun résultat")
        level: Label.Tertiary
    }
}
