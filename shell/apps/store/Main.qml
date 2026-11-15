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
    Component.onCompleted: if (tab === 3) Updates.check()

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
                Label { text: win.selected ? win.selected.summary : qsTr("Applications issues de Flathub, installées pour vous."); level: Label.Secondary }
            }
        }
        SegmentedControl {
            visible: !Flatpak.busy
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            model: [qsTr("Découvrir"), qsTr("Rechercher"), qsTr("Installées"),
                    Updates.count > 0 ? qsTr("Mises à jour (%1)").arg(Updates.count) : qsTr("Mises à jour")]
            currentIndex: win.tab
            onActivated: (i) => { win.tab = i; win.selected = null; if (i === 3 && !Updates.lastCheck.getTime()) Updates.check() }
        }
        // Tâche en cours
        Row {
            visible: Flatpak.busy
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: Theme.space3
            Label { text: Flatpak.task + (Flatpak.progress >= 0 ? " · " + Flatpak.progress + " %" : ""); level: Label.Secondary; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                width: 140; height: 6; radius: 3; color: Theme.surfaceActive
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: parent.width * Math.max(0.04, Flatpak.progress / 100); height: parent.height; radius: 3; color: Theme.accent }
            }
        }
    }

    Label {
        visible: !Flatpak.available && win.tab !== 3
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
                glyph: win.selected ? win.selected.glyph : "bag"
                tint: win.selected ? win.selected.tint : "#7358BD"
            }
        }
    }

    // ---------- Recherche sur Flathub ----------
    Column {
        visible: Flatpak.available && win.tab === 1
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
                Label { visible: !query.text; text: qsTr("Rechercher une application sur Flathub…"); level: Label.Tertiary; anchors.verticalCenter: parent.verticalCenter }
            }
            Timer { id: searchDelay; interval: 400; onTriggered: Flatpak.search(query.text) }
        }
        Label {
            visible: Flatpak.searching || (query.text.length >= 2 && Flatpak.searchResults.length === 0)
            text: Flatpak.searching ? qsTr("Recherche…") : qsTr("Aucun résultat.")
            level: Label.Secondary
        }
        ListView {
            width: parent.width
            height: parent.height - 36 - Theme.space3 * 2 - 20
            clip: true
            model: Flatpak.searchResults
            delegate: AppRow {
                required property var modelData
                width: ListView.view.width
                appId: modelData.id; name: modelData.name; summary: modelData.summary
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
                    text: Updates.status ? Updates.status
                        : Updates.count > 0 ? qsTr("%n mise(s) à jour disponible(s)", "", Updates.count)
                        : Updates.lastCheck.getTime() ? qsTr("Le système est à jour.") : qsTr("Pas encore vérifié.")
                    font.weight: Font.DemiBold
                }
                Label {
                    visible: Updates.lastCheck.getTime() > 0
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
                tint: modelData.glyph === "bag" ? "#7358BD" : "#5F6270"
                showActions: false
            }
        }
    }
}
