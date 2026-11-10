import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Bulles de notification (3 au maximum), en haut à droite, sous la barre.
// Disparition après 6 s ; un clic ferme la bulle (la notification reste dans l'historique).
Column {
    id: toasts
    spacing: Theme.space2
    width: 360
    // Pas de bulles par-dessus un panneau ouvert (elles restent dans l'historique).
    visible: ShellState.openPanel === ""

    ListModel { id: live }

    Connections {
        target: Notifications
        function onPopup(id, appName, summary, body, appIcon) {
            for (let i = 0; i < live.count; i++)
                if (live.get(i).nid === id) { live.set(i, { summary: summary, body: body }); return }
            live.insert(0, { nid: id, appName: appName, summary: summary, body: body, appIcon: appIcon })
            if (live.count > 3) live.remove(3)
        }
        function onClosed(id) { toasts.remove(id) }
    }
    function remove(id) {
        for (let i = 0; i < live.count; i++)
            if (live.get(i).nid === id) { live.remove(i); return }
    }

    Repeater {
        model: live
        delegate: Surface {
            id: toast
            required property int nid
            required property string appName
            required property string summary
            required property string body
            required property string appIcon
            kind: Surface.Strong
            elevation: 2
            width: toasts.width
            height: content.implicitHeight + Theme.space3 * 2

            opacity: 0
            Component.onCompleted: opacity = 1
            Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }

            Timer { interval: 6000; running: !hover.containsMouse; onTriggered: toasts.remove(toast.nid) }

            Row {
                id: content
                x: Theme.space3; y: Theme.space3
                width: parent.width - Theme.space3 * 2
                spacing: Theme.space3
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: Theme.surfaceActive
                    // Icône de l'application ; à défaut, pictogramme VinX.
                    Icon { anchors.centerIn: parent; name: "bell"; color: Theme.textSecondary; visible: appImg.status !== Image.Ready }
                    Image {
                        id: appImg
                        anchors.centerIn: parent
                        width: 24; height: 24
                        sourceSize: Qt.size(48, 48)
                        source: toast.appIcon && toast.appIcon[0] === "/" ? "file://" + toast.appIcon
                              : "image://theme/" + (toast.appIcon || "preferences-desktop-notification")
                    }
                }
                Column {
                    width: parent.width - 44
                    spacing: 2
                    Label { text: toast.appName; level: Label.Tertiary; font.pixelSize: Theme.fsXs; width: parent.width }
                    Label { text: toast.summary; font.weight: Font.DemiBold; width: parent.width }
                    Label {
                        visible: toast.body !== ""
                        text: toast.body
                        level: Label.Secondary
                        font.pixelSize: Theme.fsSm
                        width: parent.width
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }
            }
            MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; onClicked: toasts.remove(toast.nid) }
        }
    }
}
