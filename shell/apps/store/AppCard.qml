import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Carte d'un logiciel : logo, nom, résumé, badge de source, bouton Installer / Ouvrir.
Rectangle {
    id: card
    // { source: "debian" | "flathub", name, summary, iconUrl, icon, package, id, installed, tint }
    property var app: ({})
    signal openDetails()
    readonly property bool busy: DebianPackages.busy || Flatpak.busy
    height: 84
    radius: Theme.radiusLg
    color: hover.hovered ? Theme.surfaceHover : Theme.surfaceWindow
    border.width: 1
    border.color: Theme.border
    HoverHandler { id: hover }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.openDetails() }
    Accessible.role: Accessible.Button
    Accessible.name: card.app.name || ""

    AppLogo {
        id: logo
        x: Theme.space3; anchors.verticalCenter: parent.verticalCenter
        size: 52
        iconUrl: card.app.iconUrl || ""
        themeIcon: card.app.icon || ""
        name: card.app.name || ""
        tint: card.app.tint || "#9AA09C"
    }
    Column {
        anchors { left: logo.right; leftMargin: Theme.space3; right: parent.right; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
        spacing: 2
        Label { text: card.app.name || ""; font.weight: Font.DemiBold; width: parent.width; elide: Text.ElideRight }
        Label { text: card.app.summary || ""; level: Label.Secondary; font.pixelSize: Theme.fsSm; width: parent.width; elide: Text.ElideRight }
        Row {
            spacing: Theme.space2
            topPadding: 2
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                height: 18; radius: 5
                width: badge.implicitWidth + 12
                color: Theme.surfaceSunken
                border.width: 1; border.color: Theme.border
                Label { id: badge; anchors.centerIn: parent; text: card.app.source === "debian" ? "Debian" : "Flathub"; font.pixelSize: Theme.fsXs; level: Label.Secondary }
            }
            Label {
                visible: card.app.installed === true
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Installé"); font.pixelSize: Theme.fsXs; color: Theme.accentForeground; font.weight: Font.DemiBold
            }
        }
    }
    Button {
        anchors { right: parent.right; rightMargin: Theme.space3; bottom: parent.bottom; bottomMargin: Theme.space3 }
        visible: card.app.installed !== true && hover.hovered
        text: qsTr("Installer")
        variant: Button.Primary
        enabled: !card.busy
        onClicked: card.app.source === "debian" ? DebianPackages.install(card.app.package, card.app.name)
                                                : Flatpak.install([card.app.id], card.app.name)
    }
}
