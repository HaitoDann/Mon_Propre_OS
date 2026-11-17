import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell
import "Catalog.js" as Catalog

// Store de VinX OS : packs thématiques d'applications Flathub, installés pour l'utilisateur.
Window {
    id: win
    width: 980; height: 680
    minimumWidth: 760; minimumHeight: 500
    visible: true
    title: qsTr("Store")
    color: Theme.surfaceWindow
    AppearanceSync {}

    property var selected: null          // pack affiché en détail (null : accueil)
    property string startPage: ""
    readonly property var tabs: ["discover", "search", "installed", "updates"]
    property int tab: Math.max(0, tabs.indexOf(startPage))
    property string startQuery: ""
    Component.onCompleted: {
        if (tab === 3) Updates.check()
        if (startQuery) {
            tab = 1
            searchSource = startQuery.startsWith("debian:") ? 1 : 0
            query.text = startQuery.replace(/^debian:/, "")
        }
    }

    function showApp(a) { detail.open(a) }
    function installedCount(pack) { return pack.apps.filter(a => Flatpak.installed.indexOf(a.id) >= 0).length }

    // ---------- En-tête ----------
    Item {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space6; bottomMargin: 0 }
        height: 56
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space3
            IconButton { visible: win.selected !== null; iconName: "chevron-l"; toolTip: qsTr("Retour"); onClicked: win.selected = null; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: win.selected ? win.selected.name : qsTr("Store"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold }
                Label { text: win.selected ? win.selected.summary : qsTr("Applications Flathub et logiciels Debian, en un clic."); level: Label.Secondary }
            }
        }
        SegmentedControl {
            visible: !Flatpak.busy && !DebianPackages.busy
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            model: [qsTr("Découvrir"), qsTr("Rechercher"), qsTr("Installées"),
                    Updates.count > 0 ? qsTr("Mises à jour (%1)").arg(Updates.count) : qsTr("Mises à jour")]
            currentIndex: win.tab
            onActivated: (i) => { win.tab = i; win.selected = null; if (i === 3 && !Updates.lastCheck.getTime()) Updates.check() }
        }
        // Tâche en cours
        Row {
            visible: Flatpak.busy || DebianPackages.busy
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: Theme.space3
            Label { text: Flatpak.busy ? Flatpak.task + (Flatpak.progress >= 0 ? " · " + Flatpak.progress + " %" : "") : DebianPackages.task + (DebianPackages.progress >= 0 ? " · " + DebianPackages.progress + " %" : ""); level: Label.Secondary; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                width: 140; height: 6; radius: 3; color: Theme.surfaceActive
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: parent.width * Math.max(0.04, (Flatpak.busy ? Flatpak.progress : DebianPackages.progress) / 100); height: parent.height; radius: 3; color: Theme.accent }
            }
        }
    }

    Label {
        visible: !Flatpak.available && win.tab !== 3 && win.tab !== 1
        anchors.centerIn: parent
        text: qsTr("Flatpak n'est pas installé sur ce système : le Store est indisponible.")
        level: Label.Secondary
    }

    // ---------- Accueil : grille des packs ----------
    Flickable {
        visible: Flatpak.available && win.tab === 0 && win.selected === null
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: Theme.space6 }
        contentHeight: grid.height
        clip: true
        Grid {
            id: grid
            width: parent.width
            columns: Math.max(1, Math.floor((width + Theme.space4) / (290 + Theme.space4)))
            spacing: Theme.space4
            Repeater {
                model: Catalog.packs
                Surface {
                    id: card
                    required property var modelData
                    readonly property int done: Flatpak.installed.length >= 0 ? win.installedCount(modelData) : 0
                    kind: Surface.Sunken
                    elevation: 0
                    width: (grid.width - (grid.columns - 1) * grid.spacing) / grid.columns
                    height: 168
                    radius: Theme.radiusLg
                    Column {
                        anchors { fill: parent; margins: Theme.space4 }
                        spacing: Theme.space2
                        Row {
                            spacing: Theme.space3
                            AppIcon { size: 44; iconName: card.modelData.glyph; tint: card.modelData.tint }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Label { text: card.modelData.name; font.pixelSize: Theme.fsLg; font.weight: Font.DemiBold }
                                Label { text: qsTr("%1 applications").arg(card.modelData.apps.length); level: Label.Tertiary; font.pixelSize: Theme.fsSm }
                            }
                        }
                        Label { text: card.modelData.summary; level: Label.Secondary; font.pixelSize: Theme.fsSm; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; height: 34 }
                        Row {
                            spacing: Theme.space2
                            Button {
                                text: card.done === card.modelData.apps.length ? qsTr("Installé") : card.done > 0 ? qsTr("Compléter") : qsTr("Installer le pack")
                                // Actions d'égale priorité sur une grille : boutons neutres (cf. docs/DESIGN.md).
                                variant: Button.Secondary
                                enabled: !Flatpak.busy && card.done < card.modelData.apps.length
                                onClicked: Flatpak.install(Catalog.ids(card.modelData), qsTr("Pack %1").arg(card.modelData.name))
                            }
                            Button { text: qsTr("Détails"); variant: Button.Ghost; onClicked: win.selected = card.modelData }
                        }
                    }
                }
            }
        }
    }

    // ---------- Détail d'un pack ----------
    Column {
        visible: Flatpak.available && win.tab === 0 && win.selected !== null
        anchors { left: parent.left; right: parent.right; top: header.bottom; margins: Theme.space6 }
        Repeater {
            model: win.selected ? win.selected.apps : []
            AppRow {
                required property var modelData
                appId: modelData.id; name: modelData.name
                summary: modelData.summary + " · " + modelData.id
                onClicked: win.showApp({ source: "flathub", id: modelData.id, name: modelData.name, summary: modelData.summary,
                                         glyph: win.selected ? win.selected.glyph : "bag", tint: win.selected ? win.selected.tint : "#10DD8C" })
                glyph: win.selected ? win.selected.glyph : "bag"
                tint: win.selected ? win.selected.tint : "#10DD8C"
            }
        }
    }

    // ---------- Recherche : Flathub ou dépôt Debian ----------
    property int searchSource: 0          // 0 : applications Flathub, 1 : logiciels Debian
    property bool searchTools: false
    function runSearch() {
        if (searchSource === 0) Flatpak.search(query.text)
        else DebianPackages.search(query.text, searchTools)
    }
    Column {
        visible: win.tab === 1
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: Theme.space6 }
        spacing: Theme.space3
        onVisibleChanged: if (visible) query.forceActiveFocus()
        Rectangle {
            width: parent.width; height: 36
            radius: Theme.radiusSm
            color: Theme.surfaceSunken
            border.width: query.activeFocus ? 2 : 1
            border.color: query.activeFocus ? Theme.accentForeground : Theme.border
            Icon { id: glass; name: "search"; color: Theme.textSecondary; anchors { left: parent.left; leftMargin: Theme.space3; verticalCenter: parent.verticalCenter } }
            TextInput {
                id: query
                anchors { left: glass.right; right: parent.right; margins: Theme.space2; verticalCenter: parent.verticalCenter }
                color: Theme.text
                font.pixelSize: Theme.fsMd
                selectByMouse: true
                Accessible.name: qsTr("Rechercher une application")
                onTextChanged: searchDelay.restart()
                Label { visible: !query.text; text: win.searchSource === 0 ? qsTr("Rechercher une application sur Flathub…") : qsTr("Rechercher un logiciel dans le dépôt Debian…"); level: Label.Tertiary; anchors.verticalCenter: parent.verticalCenter }
            }
            Timer { id: searchDelay; interval: 400; onTriggered: win.runSearch() }
        }
        Row {
            spacing: Theme.space3
            SegmentedControl {
                model: [qsTr("Applications (Flathub)"), qsTr("Logiciels Debian")]
                currentIndex: win.searchSource
                onActivated: (i) => { win.searchSource = i; win.runSearch() }
            }
            Row {
                visible: win.searchSource === 1
                spacing: Theme.space2
                anchors.verticalCenter: parent.verticalCenter
                Switch { checked: win.searchTools; onToggled: (c) => { win.searchTools = c; win.runSearch() } }
                Label { text: qsTr("Inclure les outils techniques"); level: Label.Secondary; anchors.verticalCenter: parent.verticalCenter }
            }
        }
        Label {
            readonly property bool busy: win.searchSource === 0 ? Flatpak.searching : DebianPackages.searching
            readonly property int n: win.searchSource === 0 ? Flatpak.searchResults.length : DebianPackages.results.length
            visible: busy || (query.text.length >= 2 && n === 0)
            text: busy ? qsTr("Recherche…") : qsTr("Aucun résultat.")
            level: Label.Secondary
        }
        // Résultats du dépôt Debian : icône, nom, résumé, état installé.
        ListView {
            visible: win.searchSource === 1
            width: parent.width
            height: parent.height - 36 - 32 - Theme.space3 * 3 - 20
            clip: true
            model: DebianPackages.results
            delegate: Item {
                id: deb
                required property var modelData
                width: ListView.view.width; height: 64
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: win.showApp(Object.assign({ source: "debian" }, deb.modelData)) }
                Row {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    spacing: Theme.space3
                    Item {
                        width: 40; height: 40
                        Image { id: dIcon; anchors.fill: parent; source: deb.modelData.icon ? "image://theme/" + deb.modelData.icon : "image://theme/" + deb.modelData.package
                                sourceSize: Qt.size(80, 80); visible: status === Image.Ready && implicitWidth > 1 }
                        AppIcon { anchors.fill: parent; size: 40; visible: !dIcon.visible; iconName: deb.modelData.icon ? "bag" : "terminal"; tint: "#8A8983" }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label { text: deb.modelData.name; font.weight: Font.DemiBold }
                        Label { text: deb.modelData.summary || ""; level: Label.Secondary; font.pixelSize: Theme.fsSm; elide: Text.ElideRight; width: deb.width - 260 }
                    }
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: Theme.space2
                    Label { visible: deb.modelData.installed; text: qsTr("Installé"); level: Label.Secondary; anchors.verticalCenter: parent.verticalCenter }
                    Button {
                        visible: !deb.modelData.installed
                        text: qsTr("Installer"); variant: Button.Primary
                        enabled: !DebianPackages.busy
                        onClicked: DebianPackages.install(deb.modelData.package, deb.modelData.name)
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
            }
        }
        ListView {
            visible: win.searchSource === 0
            width: parent.width
            height: parent.height - 36 - 32 - Theme.space3 * 3 - 20
            clip: true
            model: Flatpak.searchResults
            delegate: AppRow {
                required property var modelData
                width: ListView.view.width
                appId: modelData.id; name: modelData.name; summary: modelData.summary
                onClicked: win.showApp({ source: "flathub", id: modelData.id, name: modelData.name, summary: modelData.summary })
            }
        }
    }

    // ---------- Applications installées ----------
    ListView {
        visible: Flatpak.available && win.tab === 2
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: Theme.space6 }
        clip: true
        model: Flatpak.installedApps
        delegate: AppRow {
            required property var modelData
            width: ListView.view.width
            appId: modelData.id; name: modelData.name
            summary: (modelData.version ? qsTr("Version %1 · ").arg(modelData.version) : "") + modelData.id
            onClicked: win.showApp({ source: "flathub", id: modelData.id, name: modelData.name, summary: modelData.id })
        }
        Label { visible: parent.count === 0; text: qsTr("Aucune application Flatpak installée."); level: Label.Secondary }
    }

    // ---------- Mises à jour ----------
    Item {
        visible: win.tab === 3
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: Theme.space6 }
        Item {
            id: updHead
            width: parent.width; height: 48
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    text: Updates.applying ? qsTr("Installation des mises à jour")
                        : Updates.status ? Updates.status
                        : Updates.count > 0 ? qsTr("%n mise(s) à jour disponible(s)", "", Updates.count)
                        : Updates.lastCheck.getTime() ? qsTr("Le système est à jour.") : qsTr("Pas encore vérifié.")
                    font.weight: Font.DemiBold
                }
                // Installation en arrière-plan : progression en direct.
                Column {
                    visible: Updates.applying
                    spacing: 4
                    Label { text: Updates.stepLabel + (Updates.progress >= 0 ? " · " + Updates.progress + " %" : ""); level: Label.Secondary; font.pixelSize: Theme.fsSm }
                    Rectangle {
                        width: 320; height: 5; radius: 2.5; color: Theme.surfaceActive
                        Rectangle { height: parent.height; radius: 2.5; color: Theme.accent; width: parent.width * Math.max(0.03, Math.max(0, Updates.progress) / 100)
                                    Behavior on width { NumberAnimation { duration: Theme.durNormal } } }
                    }
                    Label { text: qsTr("Vous pouvez fermer le Store : l'installation continue."); level: Label.Tertiary; font.pixelSize: Theme.fsXs }
                }
                Label {
                    visible: Updates.lastCheck.getTime() > 0 && !Updates.applying
                    text: qsTr("Dernière vérification : %1").arg(Qt.formatDateTime(Updates.lastCheck, "dd/MM/yyyy HH:mm"))
                    level: Label.Tertiary; font.pixelSize: Theme.fsSm
                }
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Theme.space2
                Button { text: qsTr("Vérifier"); variant: Button.Secondary; enabled: !Updates.checking && !Updates.applying; onClicked: Updates.check() }
                Button { text: qsTr("Tout mettre à jour"); variant: Button.Primary; enabled: Updates.count > 0 && !Updates.checking && !Updates.applying; onClicked: Updates.applyAll() }
            }
        }
        ListView {
            anchors { left: parent.left; right: parent.right; top: updHead.bottom; bottom: parent.bottom; topMargin: Theme.space3 }
            clip: true
            model: Updates.apps.map(a => ({ title: a.name || a.id, detail: qsTr("Application") + " · " + (a.version ? a.version + " · " : "") + a.id, glyph: "bag" }))
                   .concat(Updates.system.map(p => ({ title: p.name, detail: qsTr("Système") + " · " + p.from + " → " + p.version, glyph: "terminal" })))
            delegate: AppRow {
                required property var modelData
                width: ListView.view.width
                name: modelData.title; summary: modelData.detail; glyph: modelData.glyph
                tint: modelData.glyph === "bag" ? "#10DD8C" : "#5F6270"
                showActions: false
            }
        }
    }

    AppDetail { id: detail }
}
