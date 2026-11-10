import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell

// Paramètres de VinX OS. Les réglages sont enregistrés dans les préférences partagées :
// le shell les applique immédiatement.
Window {
    id: win
    width: 920; height: 640
    minimumWidth: 760; minimumHeight: 480
    visible: true
    title: qsTr("Paramètres")
    color: Theme.surfaceWindow

    property string startPage: ""
    AppearanceSync {}

    readonly property int rev: Preferences.revision
    function pref(key, def) { rev; return Preferences.value(key, def) }
    function on(key, def) { const v = pref(key, def); return v === true || v === "true" }

    readonly property var pages: [
        { id: "appearance", title: qsTr("Apparence"), icon: "sun" },
        { id: "wallpaper", title: qsTr("Fond d'écran"), icon: "image" },
        { id: "desktop", title: qsTr("Bureau"), icon: "grid" },
        { id: "dock", title: qsTr("Dock"), icon: "folder" },
        { id: "notifications", title: qsTr("Notifications"), icon: "bell" },
        { id: "about", title: qsTr("À propos"), icon: "info" }
    ]
    property string page: pages.some(p => p.id === startPage) ? startPage : "appearance"

    // ---------- Barre latérale ----------
    Rectangle {
        id: sidebar
        width: 220
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        color: Theme.surfaceSunken
        Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.border }
        Column {
            anchors { fill: parent; margins: Theme.space3; topMargin: Theme.space4 }
            spacing: 2
            Label { text: qsTr("Paramètres"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; height: 40; leftPadding: Theme.space2 }
            Repeater {
                model: win.pages
                Rectangle {
                    required property var modelData
                    width: parent.width; height: 34
                    radius: Theme.radiusSm
                    color: win.page === modelData.id ? Theme.surfaceActive : navMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    Row {
                        anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                        spacing: Theme.space2
                        Icon { name: modelData.icon; color: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: modelData.title; font.weight: win.page === modelData.id ? Font.DemiBold : Font.Normal }
                    }
                    MouseArea { id: navMouse; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = modelData.id }
                }
            }
        }
    }

    // ---------- Contenu ----------
    Flickable {
        anchors { left: sidebar.right; right: parent.right; top: parent.top; bottom: parent.bottom }
        contentHeight: content.height + Theme.space6 * 2
        clip: true
        Column {
            id: content
            x: Theme.space6; y: Theme.space6
            width: parent.width - Theme.space6 * 2
            spacing: Theme.space2

            Label { text: win.pages.find(p => p.id === win.page).title; font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; height: 36 }

            // Apparence
            Column {
                visible: win.page === "appearance"
                width: parent.width
                SettingsRow {
                    title: qsTr("Thème")
                    description: qsTr("S'applique à la barre, au dock et aux fenêtres des applications.")
                    SegmentedControl {
                        model: [qsTr("Clair"), qsTr("Sombre")]
                        currentIndex: Theme.dark ? 1 : 0
                        onActivated: (i) => Preferences.setValue("appearance/dark", i === 1)
                    }
                }
                SettingsRow {
                    title: qsTr("Couleur d'accent")
                    description: qsTr("Boutons principaux, éléments actifs et sélection.")
                    Row {
                        spacing: Theme.space2
                        Repeater {
                            model: ["", "#3B82C4", "#3E8460", "#B8693F", "#A8514F", "#6B6E76"]
                            Rectangle {
                                required property string modelData
                                readonly property bool current: String(win.pref("appearance/accent", "")) === modelData
                                width: 22; height: 22; radius: 11
                                color: modelData === "" ? (Theme.dark ? "#5B65C9" : "#4E58BE") : modelData
                                border.width: current ? 2 : 0
                                border.color: Theme.text
                                Accessible.role: Accessible.RadioButton
                                Accessible.name: modelData === "" ? qsTr("Indigo (par défaut)") : modelData
                                MouseArea { anchors.fill: parent; onClicked: Preferences.setValue("appearance/accent", parent.modelData) }
                            }
                        }
                    }
                }
            }

            // Fond d'écran
            Flow {
                visible: win.page === "wallpaper"
                width: parent.width
                spacing: Theme.space4
                Repeater {
                    model: Session.wallpapers()
                    Column {
                        required property var modelData
                        readonly property bool current: String(win.pref("desktop/wallpaper", "/usr/share/wallpapers/VinX-Graphite/contents/images/3840x2160.png")) === modelData.path
                        spacing: Theme.space2
                        Rectangle {
                            width: 200; height: 112; radius: Theme.radiusMd
                            color: Theme.surfaceSunken
                            border.width: parent.current ? 2 : 1
                            border.color: parent.current ? Theme.accentForeground : Theme.border
                            Image {
                                anchors { fill: parent; margins: 3 }
                                source: "file://" + modelData.preview
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(400, 224)
                                asynchronous: true
                            }
                            MouseArea { anchors.fill: parent; onClicked: Preferences.setValue("desktop/wallpaper", modelData.path) }
                        }
                        Label { text: modelData.name; level: parent.current ? Label.Primary : Label.Secondary; font.pixelSize: Theme.fsSm; width: 200 }
                    }
                }
                Label { visible: Session.wallpapers().length === 0; text: qsTr("Aucun fond d'écran installé."); level: Label.Secondary }
            }

            // Bureau
            Column {
                visible: win.page === "desktop"
                width: parent.width
                SettingsRow { title: qsTr("Widget Horloge"); Switch { checked: win.on("widgets/clock", true); onToggled: (c) => Preferences.setValue("widgets/clock", c) } }
                SettingsRow { title: qsTr("Widget Calendrier"); Switch { checked: win.on("widgets/calendar", false); onToggled: (c) => Preferences.setValue("widgets/calendar", c) } }
                SettingsRow { title: qsTr("Widget Note rapide"); Switch { checked: win.on("widgets/note", false); onToggled: (c) => Preferences.setValue("widgets/note", c) } }
                SettingsRow {
                    title: qsTr("Espaces de travail et fenêtres")
                    description: qsTr("Nombre de bureaux, raccourcis et magnétisme des fenêtres.")
                    Button { text: qsTr("Réglages avancés…"); onClicked: Session.launch("systemsettings", ["kcm_kwin_virtualdesktops"]) }
                }
            }

            // Dock
            Column {
                visible: win.page === "dock"
                width: parent.width
                SettingsRow {
                    title: qsTr("Taille des icônes")
                    description: qsTr("%1 px").arg(Math.round(sizeSlider.value))
                    Slider {
                        id: sizeSlider
                        width: 220
                        from: 40; to: 64; stepSize: 2
                        value: Number(win.pref("dock/iconSize", Theme.dockIcon))
                        onMoved: (v) => Preferences.setValue("dock/iconSize", Math.round(v))
                    }
                }
                SettingsRow { title: qsTr("Agrandissement au survol"); Switch { checked: win.on("dock/magnify", true); onToggled: (c) => Preferences.setValue("dock/magnify", c) } }
            }

            // Notifications
            Column {
                visible: win.page === "notifications"
                width: parent.width
                SettingsRow {
                    title: qsTr("Ne pas déranger")
                    description: qsTr("Masque les bulles ; les notifications restent dans le calendrier.")
                    Switch { checked: win.on("notifications/dnd", false); onToggled: (c) => Preferences.setValue("notifications/dnd", c) }
                }
            }

            // À propos
            Column {
                visible: win.page === "about"
                width: parent.width
                spacing: Theme.space4
                Row {
                    spacing: Theme.space4
                    Icon { name: "vinx"; width: 64; height: 46; color: Theme.logo; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label { text: Session.osName; font.pixelSize: Theme.fsLg; font.weight: Font.DemiBold }
                        Label { text: qsTr("Simple. Ergonomique. Stable."); level: Label.Secondary }
                    }
                }
                Column {
                    width: parent.width
                    SettingsRow { title: qsTr("Nom de l'ordinateur"); Label { text: Session.hostName(); level: Label.Secondary } }
                    SettingsRow { title: qsTr("Utilisateur"); Label { text: Session.userName; level: Label.Secondary } }
                    SettingsRow { title: qsTr("Noyau Linux"); Label { text: Session.kernelVersion(); level: Label.Secondary } }
                    SettingsRow {
                        title: qsTr("Réglages du matériel et du système")
                        description: qsTr("Écrans, réseau, imprimantes, comptes…")
                        Button { text: qsTr("Ouvrir…"); onClicked: Session.launch("systemsettings") }
                    }
                }
            }
        }
    }
}
