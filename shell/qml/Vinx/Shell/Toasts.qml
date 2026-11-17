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

    // Branchement d'un écran : choix Étendre / Dupliquer / Seulement lui.
    DisplayHotplug { }

    // Vérification automatique des mises à jour (session VinX réelle uniquement) :
    // 3 min après l'ouverture de session, puis toutes les 6 h.
    Timer {
        id: updateTimer
        readonly property int rev: Preferences.revision
        running: Session.environment("VINX_SESSION") === "1"
                 && (rev, String(Preferences.value("updates/autoCheck", true)) !== "false")
        interval: 3 * 60 * 1000
        repeat: true
        onTriggered: { interval = 6 * 3600 * 1000; Updates.check() }
    }
    property int notifiedCount: 0
    Connections {
        target: Updates
        function onFinished(ok) {
            if (Updates.applying || Updates.checking || Updates.count === 0) return
            // Option : les applications (Flathub) se mettent à jour seules, sans mot de passe.
            if (Updates.apps.length > 0 && String(Preferences.value("updates/autoApps", false)) === "true") {
                Updates.applyAll(true)
                if (Updates.system.length === 0) return
            }
            if (Updates.count === toasts.notifiedCount) return
            toasts.notifiedCount = Updates.count
            Notifications.notifyFull(qsTr("Mises à jour"), qsTr("Mises à jour disponibles"),
                                     qsTr("%n mise(s) à jour prête(s) à être installée(s).", "", Updates.count),
                                     ["vinx-updates", qsTr("Afficher")], { "desktop-entry": "org.vinx.store" })
        }
    }
    Connections {
        target: Notifications
        function onActionInvoked(id, key) { if (key === "vinx-updates") Session.launch("vinx-updates") }
    }
    Connections {
        target: Notifications
        function onPopup(id) {
            const n = Notifications.get(id)
            const entry = { nid: id, appName: n.appName || "", summary: n.summary, body: n.body, appIcon: n.appIcon || "",
                            critical: n.urgency === 2, actionsJson: JSON.stringify(n.actions || []) }
            for (let i = 0; i < live.count; i++)
                if (live.get(i).nid === id) { live.set(i, entry); return }
            live.insert(0, entry)
            if (live.count > 3) live.remove(3)
        }
        function onClosed(id) { toasts.remove(id) }
        // Notification sans action par défaut : on ouvre l'application qui l'a envoyée.
        function onLaunchRequested(desktopEntry) { Applications.launch(desktopEntry) }
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
            required property bool critical
            required property string actionsJson
            readonly property var actions: JSON.parse(actionsJson)
            kind: Surface.Strong
            elevation: 2
            width: toasts.width
            height: content.implicitHeight + Theme.space3 * 2 + (actionRow.visible ? actionRow.height + Theme.space2 : 0)
            borderColor: critical ? Theme.danger : Theme.borderStrong

            // Arrivée signature : glissement le long de la diagonale du biseau, trait d'accent.
            opacity: 0
            property real shift: 14
            transform: Translate { x: toast.shift; y: -toast.shift }
            Behavior on shift { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }
            Behavior on edgeProgress { NumberAnimation { duration: Theme.durSlow; easing.type: Easing.OutCubic } }
            Component.onCompleted: { opacity = 1; shift = 0; edgeProgress = 1 }
            Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }

            // Les notifications critiques restent affichées jusqu'à ce qu'on les ferme.
            Timer { interval: 6000; running: !toast.critical && !hover.containsMouse; onTriggered: toasts.remove(toast.nid) }

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
            // Clic : action par défaut de l'application (ou ouverture de l'application).
            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: { toasts.remove(toast.nid); Notifications.activate(toast.nid) }
            }
            IconButton {
                anchors { right: parent.right; top: parent.top; margins: 6 }
                width: 22; height: 22
                flat: true
                iconName: "close"
                toolTip: qsTr("Fermer")
                visible: hover.containsMouse || toast.critical
                onClicked: toasts.remove(toast.nid)
            }
            // Boutons d'action (« Répondre », « Ouvrir »…).
            Row {
                id: actionRow
                visible: toast.actions.length > 0
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.space3 }
                spacing: Theme.space2
                Repeater {
                    model: toast.actions
                    Button {
                        required property var modelData
                        text: modelData.label
                        onClicked: { toasts.remove(toast.nid); Notifications.invokeAction(toast.nid, modelData.key) }
                    }
                }
            }
        }
    }
}
