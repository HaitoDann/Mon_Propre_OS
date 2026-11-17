import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Réseaux Wi-Fi à proximité : un clic pour se connecter, mot de passe demandé sur place.
// Utilisé dans le centre de contrôle et dans Paramètres → Réseau.
Column {
    id: root
    property real listHeight: 260
    property string expanded: ""        // réseau dont le champ de mot de passe est ouvert
    property string message: ""
    property bool messageOk: true
    property bool showHidden: false
    spacing: Theme.space2

    Component.onCompleted: Wifi.refresh(true)
    Connections {
        target: Wifi
        function onFinished(ok, msg) { root.message = msg; root.messageOk = ok; if (ok) root.expanded = "" }
    }
    function bars(s) { return s >= 70 ? "wifi" : s >= 45 ? "wifi-3" : s >= 25 ? "wifi-2" : "wifi-1" }
    function choose(n) {
        root.message = ""
        if (n.active) return
        if (n.secure && !n.known) { root.expanded = root.expanded === n.ssid ? "" : n.ssid; return }
        Wifi.connectTo(n.ssid)
    }

    // En-tête : interrupteur et actualisation
    Item {
        width: parent.width; height: 28
        Label { text: qsTr("Wi-Fi"); font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: Theme.space2
            IconButton {
                flat: true; width: 26; height: 26
                iconName: "restart"; toolTip: qsTr("Rechercher les réseaux")
                visible: Wifi.enabled
                enabled: !Wifi.scanning
                onClicked: Wifi.refresh(true)
                RotationAnimation on rotation { running: Wifi.scanning; loops: Animation.Infinite; from: 0; to: 360; duration: 900 }
            }
            Switch { checked: Wifi.enabled; onToggled: (c) => Wifi.enabled = c }
        }
    }

    Label {
        visible: !Wifi.available || !Wifi.enabled || (Wifi.networks.length === 0 && !Wifi.scanning)
        width: parent.width; wrapMode: Text.WordWrap
        text: !Wifi.available ? qsTr("Pas de carte Wi-Fi détectée.")
            : !Wifi.enabled ? qsTr("Le Wi-Fi est désactivé.")
            : qsTr("Aucun réseau trouvé.")
        level: Label.Secondary
    }

    ListView {
        id: list
        visible: Wifi.enabled && Wifi.networks.length > 0
        width: parent.width
        height: Math.min(root.listHeight, contentHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Wifi.networks
        spacing: 2
        delegate: Column {
            id: net
            required property var modelData
            width: list.width
            readonly property bool open: root.expanded === modelData.ssid
            Rectangle {
                width: parent.width; height: 40
                radius: Theme.radiusSm
                color: net.modelData.active ? Theme.surfaceActive : rowHover.hovered ? Theme.surfaceHover : "transparent"
                Row {
                    anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                    spacing: Theme.space2
                    Icon { name: root.bars(net.modelData.signal); color: net.modelData.active ? Theme.accentForeground : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label { text: net.modelData.ssid; font.weight: net.modelData.active ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; width: list.width - 110 }
                        Label {
                            visible: text !== ""
                            text: Wifi.pending === net.modelData.ssid ? qsTr("Connexion…")
                                : net.modelData.active ? qsTr("Connecté") : net.modelData.known ? qsTr("Enregistré") : ""
                            level: Label.Secondary; font.pixelSize: Theme.fsXs
                        }
                    }
                }
                Row {
                    anchors { right: parent.right; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                    spacing: Theme.space1
                    // Actions d'un réseau enregistré, au survol.
                    Button {
                        visible: rowHover.hovered && net.modelData.active
                        text: qsTr("Déconnecter"); variant: Button.Ghost; height: 26
                        onClicked: Wifi.disconnectCurrent()
                    }
                    Button {
                        visible: rowHover.hovered && net.modelData.known && !net.modelData.active
                        text: qsTr("Oublier"); variant: Button.Ghost; height: 26
                        onClicked: Wifi.forget(net.modelData.ssid)
                    }
                    Icon { visible: net.modelData.secure; name: "lock"; width: 14; height: 14; color: Theme.textTertiary; anchors.verticalCenter: parent.verticalCenter }
                }
                HoverHandler { id: rowHover }
                MouseArea { anchors.fill: parent; z: -1; onClicked: root.choose(net.modelData) }
            }
            // Mot de passe
            Row {
                visible: net.open
                spacing: Theme.space2
                leftPadding: Theme.space2; topPadding: 4; bottomPadding: 6
                Rectangle {
                    width: list.width - 110; height: 32; radius: Theme.radiusSm
                    color: Theme.surfaceSunken; border.width: pw.activeFocus ? 2 : 1
                    border.color: pw.activeFocus ? Theme.accentForeground : Theme.border
                    TextInput {
                        id: pw
                        anchors { fill: parent; leftMargin: Theme.space2; rightMargin: Theme.space2 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password; passwordCharacter: "●"
                        color: Theme.text; font.pixelSize: Theme.fsMd; clip: true
                        Accessible.name: qsTr("Mot de passe du Wi-Fi")
                        onVisibleChanged: if (visible) forceActiveFocus()
                        onAccepted: if (text) Wifi.connectTo(net.modelData.ssid, text)
                        Keys.onEscapePressed: root.expanded = ""
                        Label { visible: !pw.text; text: qsTr("Mot de passe"); level: Label.Tertiary; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
                Button { text: qsTr("Se connecter"); variant: Button.Primary; enabled: pw.text.length >= 8 && !Wifi.busy; onClicked: Wifi.connectTo(net.modelData.ssid, pw.text) }
            }
        }
    }

    // Réseau masqué
    MenuItem {
        visible: Wifi.enabled
        width: parent.width
        text: qsTr("Réseau masqué…")
        iconName: "plus"
        onTriggered: root.showHidden = !root.showHidden
    }
    Column {
        visible: root.showHidden && Wifi.enabled
        width: parent.width
        spacing: Theme.space2
        Repeater {
            model: [{ ph: qsTr("Nom du réseau"), pass: false }, { ph: qsTr("Mot de passe (vide si ouvert)"), pass: true }]
            delegate: Rectangle {
                required property var modelData
                required property int index
                property alias text: field.text
                width: root.width; height: 32; radius: Theme.radiusSm
                color: Theme.surfaceSunken; border.width: 1; border.color: Theme.border
                TextInput {
                    id: field
                    anchors { fill: parent; leftMargin: Theme.space2; rightMargin: Theme.space2 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: modelData.pass ? TextInput.Password : TextInput.Normal; passwordCharacter: "●"
                    color: Theme.text; font.pixelSize: Theme.fsMd; clip: true
                    Label { visible: !field.text; text: modelData.ph; level: Label.Tertiary; anchors.verticalCenter: parent.verticalCenter }
                }
                Component.onCompleted: if (index === 0) hiddenName = this; else hiddenPass = this
            }
        }
        Button {
            text: qsTr("Se connecter")
            variant: Button.Primary
            enabled: hiddenName && hiddenName.text !== "" && !Wifi.busy
            onClicked: Wifi.connectTo(hiddenName.text, hiddenPass.text, true)
        }
    }
    property Item hiddenName: null
    property Item hiddenPass: null

    Label {
        visible: root.message !== ""
        width: parent.width; wrapMode: Text.WordWrap
        text: root.message
        color: root.messageOk ? Theme.accentForeground : Theme.danger
        font.pixelSize: Theme.fsSm
    }

}
