import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Ligne d'application : icône, nom, description, boutons Ouvrir / Installer / Supprimer.
Item {
    id: row
    property string appId
    property string name
    property string summary
    property string glyph: "bag"
    property color tint: "#7358BD"
    property bool showActions: true
    readonly property bool isInstalled: Flatpak.installed.indexOf(appId) >= 0
    width: parent ? parent.width : 400
    height: 64

    Row {
        anchors { left: parent.left; right: actions.left; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
        spacing: Theme.space3
        AppIcon { size: 40; iconName: row.glyph; tint: row.tint }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 40 - Theme.space3
            Label { text: row.name; font.weight: Font.DemiBold; elide: Text.ElideRight; width: parent.width }
            Label { text: row.summary; level: Label.Secondary; font.pixelSize: Theme.fsSm; elide: Text.ElideRight; width: parent.width }
        }
    }
    Row {
        id: actions
        visible: row.showActions
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: Theme.space2
        Button { visible: row.isInstalled; text: qsTr("Ouvrir"); onClicked: Flatpak.launch(row.appId) }
        Button {
            text: row.isInstalled ? qsTr("Supprimer") : qsTr("Installer")
            variant: row.isInstalled ? Button.Ghost : Button.Primary
            enabled: !Flatpak.busy
            onClicked: row.isInstalled ? Flatpak.uninstall([row.appId], row.name) : Flatpak.install([row.appId], row.name)
        }
    }
    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Theme.border }
}
