import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Fiche d'une application (Flathub ou dépôt Debian) : description, version, taille, licence,
// installation ou suppression. S'ouvre par-dessus la page, depuis n'importe quel onglet.
Item {
    id: root
    anchors.fill: parent
    visible: app !== null
    z: 50
    // { source: "flathub" | "debian", id, name, summary, icon, package, glyph, tint }
    property var app: null
    property var info: ({})
    readonly property bool debian: app && app.source === "debian"
    readonly property bool installed: !app ? false
        : debian ? (app.installed === true || installedNow) : Flatpak.installed.indexOf(app.id) >= 0
    property bool installedNow: false

    function formatSize(b) {
        const u = ["octets", "Ko", "Mo", "Go"]; let i = 0
        while (b >= 1024 && i < 3) { b /= 1024; i++ }
        return (i ? b.toFixed(b < 10 ? 1 : 0).replace(".", ",") : b) + " " + u[i]
    }
    function open(a) {
        app = a; info = ({}); installedNow = false
        if (a.source === "debian") DebianPackages.details(a.package); else Flatpak.details(a.id)
    }
    Connections { target: DebianPackages; function onDetailsReady(pkg, i) { if (root.app && root.app.package === pkg) root.info = i }
                  function onFinished(ok) { if (ok && root.app && root.debian) root.installedNow = !root.installed } }
    Connections { target: Flatpak; function onDetailsReady(id, i) { if (root.app && root.app.id === id) root.info = i } }
    Keys.onEscapePressed: app = null

    Rectangle { anchors.fill: parent; color: "#33000000"; MouseArea { anchors.fill: parent; onClicked: root.app = null } }

    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: Math.min(460, parent.width - 80)
        color: Theme.surfaceWindow
        Rectangle { width: 1; height: parent.height; color: Theme.border }
        MouseArea { anchors.fill: parent }

        Flickable {
            anchors { fill: parent; margins: Theme.space6 }
            contentHeight: col.height
            clip: true
            Column {
                id: col
                width: parent.width
                spacing: Theme.space4
                IconButton { iconName: "close"; toolTip: qsTr("Fermer"); onClicked: root.app = null; anchors.right: parent.right }
                Row {
                    spacing: Theme.space4
                    Item {
                        width: 72; height: 72
                        Image {
                            id: logo
                            anchors.fill: parent
                            source: root.app && root.app.icon ? "image://theme/" + root.app.icon : root.app && !root.debian ? "image://theme/" + root.app.id : ""
                            sourceSize: Qt.size(144, 144)
                            visible: status === Image.Ready && implicitWidth > 1
                        }
                        AppIcon { anchors.fill: parent; size: 72; visible: !logo.visible; iconName: root.app ? (root.app.glyph || "bag") : "bag"; tint: root.app && root.app.tint ? root.app.tint : "#10DD8C" }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: col.width - 72 - Theme.space4
                        Label { text: root.app ? root.app.name : ""; font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; width: parent.width; wrapMode: Text.WordWrap }
                        Label { text: root.info.summary || (root.app ? root.app.summary : ""); level: Label.Secondary; width: parent.width; wrapMode: Text.WordWrap }
                        Label { text: root.debian ? qsTr("Dépôt Debian") : qsTr("Flathub"); level: Label.Tertiary; font.pixelSize: Theme.fsXs }
                    }
                }
                Row {
                    spacing: Theme.space2
                    Button {
                        visible: !root.installed
                        text: qsTr("Installer"); variant: Button.Primary
                        enabled: !Flatpak.busy && !DebianPackages.busy
                        onClicked: root.debian ? DebianPackages.install(root.app.package, root.app.name) : Flatpak.install([root.app.id], root.app.name)
                    }
                    Button {
                        visible: root.installed && !root.debian
                        text: qsTr("Ouvrir"); variant: Button.Primary
                        onClicked: Flatpak.launch(root.app.id)
                    }
                    Button {
                        visible: root.installed && root.debian && root.app && root.app.id.endsWith(".desktop")
                        text: qsTr("Ouvrir"); variant: Button.Primary
                        onClicked: Applications.launch(root.app.id.replace(/\\.desktop$/, ""))
                    }
                    Button {
                        visible: root.installed
                        text: qsTr("Supprimer"); variant: Button.Ghost
                        enabled: !Flatpak.busy && !DebianPackages.busy
                        onClicked: root.debian ? DebianPackages.remove(root.app.package, root.app.name) : Flatpak.uninstall([root.app.id], root.app.name)
                    }
                }
                // Progression de l'opération en cours
                Column {
                    visible: (root.debian && DebianPackages.busy) || (!root.debian && Flatpak.busy)
                    width: parent.width; spacing: 4
                    Label { text: root.debian ? DebianPackages.task : Flatpak.task; level: Label.Secondary; font.pixelSize: Theme.fsSm }
                    Rectangle {
                        width: parent.width; height: 4; radius: 2; color: Theme.surfaceActive
                        Rectangle { height: parent.height; radius: 2; color: Theme.accent
                            width: parent.width * Math.max(0.04, (root.debian ? DebianPackages.progress : Flatpak.progress) / 100) }
                    }
                }
                Label {
                    visible: !!root.info.description
                    text: root.info.description || ""
                    width: parent.width; wrapMode: Text.WordWrap
                    lineHeight: 1.15
                }
                // Informations
                Column {
                    width: parent.width
                    Repeater {
                        model: [[qsTr("Version"), root.info.version], [qsTr("Licence"), root.info.license],
                                [qsTr("Téléchargement"), root.info.download],
                                [qsTr("Taille installée"), root.info.installedSize > 0 ? root.formatSize(root.info.installedSize) : root.info.installedSize],
                                [qsTr("Paquet"), root.debian && root.app ? root.app.package : (root.app ? root.app.id : "")]]
                        delegate: Item {
                            required property var modelData
                            visible: !!modelData[1]
                            width: col.width; height: visible ? 30 : 0
                            Label { text: modelData[0]; level: Label.Secondary; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: String(modelData[1] || ""); anchors { right: parent.right; verticalCenter: parent.verticalCenter } elide: Text.ElideMiddle; width: parent.width * 0.6; horizontalAlignment: Text.AlignRight }
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
                        }
                    }
                }
                Button {
                    text: root.debian ? qsTr("Site du projet") : qsTr("Voir sur Flathub (captures, avis)")
                    variant: Button.Ghost
                    visible: !root.debian || !!root.info.homepage
                    onClicked: Qt.openUrlExternally(root.debian ? root.info.homepage : "https://flathub.org/apps/" + root.app.id)
                }
            }
        }
    }
}
