import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.Viewer

// Panneau Infos (touche I) : fichier, dimensions, date de prise de vue, appareil, dossier.
Rectangle {
    id: panel
    color: "#161817"
    signal closeRequested()
    signal wallpaper()
    function n(v, d) { return Number(v).toLocaleString(Qt.locale(), "f", d) }
    readonly property var rows: {
        const i = Viewer.info
        const out = [[qsTr("Fichier"), i.name], [qsTr("Taille"), i.bytes >= 1048576 ? qsTr("%1 Mo").arg(n(i.bytes / 1048576, 1)) : qsTr("%1 ko").arg(n(i.bytes / 1024, 0))]]
        if (i.width > 0) out.push([qsTr("Dimensions"), qsTr("%1 × %2 pixels").arg(i.width).arg(i.height)])
        if (i.format) out.push([qsTr("Format"), i.format])
        if (i.taken) out.push([qsTr("Prise le"), i.taken])
        else if (i.modified) out.push([qsTr("Modifiée le"), i.modified])
        if (i.camera) out.push([qsTr("Appareil"), i.camera])
        if (i.settings) out.push([qsTr("Réglages"), i.settings])
        return out
    }
    Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 1; color: "#1AFFFFFF" }
    Flickable {
        anchors { fill: parent; margins: Theme.space4; leftMargin: Theme.space5 }
        contentHeight: column.height
        clip: true
        Column {
            id: column
            width: 250
            spacing: Theme.space3
            Item {
                width: parent.width; height: 28
                Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Infos"); color: "#FFFFFF"; font.pixelSize: Theme.fsLg; font.weight: Font.DemiBold }
                Rectangle {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: 28; height: 28; radius: 14
                    color: closeMouse.containsMouse ? "#1FFFFFFF" : "transparent"
                    Icon { anchors.centerIn: parent; width: 14; height: 14; name: "close"; color: "#D8D8D6" }
                    MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: panel.closeRequested() }
                }
            }
            Repeater {
                model: panel.rows
                Column {
                    required property var modelData
                    width: parent.width
                    spacing: 2
                    Label { text: modelData[0].toUpperCase(); color: "#7A7D7A"; font.pixelSize: Theme.fsXs; font.weight: Font.DemiBold; font.letterSpacing: 0.4 }
                    Label { width: parent.width; text: modelData[1]; color: "#ECECEA"; wrapMode: Text.WrapAnywhere }
                }
            }
            Column {
                width: parent.width
                spacing: 2
                Label { text: qsTr("Dossier").toUpperCase(); color: "#7A7D7A"; font.pixelSize: Theme.fsXs; font.weight: Font.DemiBold; font.letterSpacing: 0.4 }
                Label {
                    width: parent.width
                    text: Viewer.info.folder || ""
                    color: Theme.accent
                    wrapMode: Text.WrapAnywhere
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Viewer.openFolder() }
                }
            }
            Flow {
                width: parent.width
                spacing: Theme.space2
                topPadding: Theme.space2
                DarkChip { text: qsTr("Ouvrir avec…"); checked: true; anchors.verticalCenter: undefined; onClicked: Viewer.openWith() }
                DarkChip { text: qsTr("Fond d'écran"); checked: true; anchors.verticalCenter: undefined; onClicked: panel.wallpaper() }
            }
        }
    }
}
