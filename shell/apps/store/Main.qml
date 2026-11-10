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
                Label { text: win.selected ? win.selected.name : qsTr("Store"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold }
                Label { text: win.selected ? win.selected.summary : qsTr("Ajoutez des fonctionnalités en un clic. Applications issues de Flathub."); level: Label.Secondary }
            }
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
        visible: !Flatpak.available
        anchors.centerIn: parent
        text: qsTr("Flatpak n'est pas installé sur ce système : le Store est indisponible.")
        level: Label.Secondary
    }

    // ---------- Accueil : grille des packs ----------
    Flickable {
        visible: Flatpak.available && win.selected === null
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
        visible: Flatpak.available && win.selected !== null
        anchors { left: parent.left; right: parent.right; top: header.bottom; margins: Theme.space6 }
        Repeater {
            model: win.selected ? win.selected.apps : []
            Item {
                id: row
                required property var modelData
                readonly property bool isInstalled: Flatpak.installed.indexOf(modelData.id) >= 0
                width: parent.width; height: 64
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.space3
                    AppIcon { size: 40; iconName: win.selected ? win.selected.glyph : "bag"; tint: win.selected ? win.selected.tint : "#5B65C9" }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label { text: row.modelData.name; font.weight: Font.DemiBold }
                        Label { text: row.modelData.summary + " · " + row.modelData.id; level: Label.Secondary; font.pixelSize: Theme.fsSm }
                    }
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: Theme.space2
                    Button { visible: row.isInstalled; text: qsTr("Ouvrir"); onClicked: Flatpak.launch(row.modelData.id) }
                    Button {
                        text: row.isInstalled ? qsTr("Supprimer") : qsTr("Installer")
                        variant: row.isInstalled ? Button.Ghost : Button.Primary
                        enabled: !Flatpak.busy
                        onClicked: row.isInstalled ? Flatpak.uninstall([row.modelData.id], row.modelData.name) : Flatpak.install([row.modelData.id], row.modelData.name)
                    }
                }
                Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Theme.border }
            }
        }
    }
}
