import QtQuick
import Vinx.Theme
import Vinx.Controls

// Vitrine du design system VinX : chaque composant, dans les deux thèmes.
Window {
    id: win
    width: 1120; height: 780
    minimumWidth: 760; minimumHeight: 520
    visible: true
    title: "VinX — Design system"
    color: Theme.background

    // Options de démarrage (voir main.cpp)
    property bool startLight: false
    property string startOpen: ""
    Component.onCompleted: if (startLight) Theme.dark = false
    // Ouverture différée : après la mise en page, pour que l'ancrage soit correct.
    Timer {
        interval: 150
        running: win.startOpen !== ""
        onTriggered: win.startOpen === "cc" ? cc.show(ccBtn) : menu.show(menuBtn)
    }

    readonly property var apps: [
        ["folder", "#4F8BFF", "#2F5BEA", "Fichiers"], ["globe", "#FF9A3C", "#E8492F", "Firefox"],
        ["doc", "#5B8DEF", "#3753C9", "Documents"], ["table", "#34C47C", "#14915A", "Tableur"],
        ["mail", "#3EC5F2", "#1D8FD6", "Courrier"], ["calendar", "#FF6B6B", "#D83A4F", "Calendrier"],
        ["bag", "#C084FC", "#7C3AED", "Store"], ["sliders", "#8A93A6", "#565E70", "Paramètres"]
    ]
    readonly property var icons: ["search", "wifi", "wifi-off", "bluetooth", "volume", "volume-off", "brightness",
        "battery", "bell", "bell-off", "moon", "sun", "power", "lock", "restart", "logout", "info", "grid", "plus",
        "check", "close", "minus", "expand", "fullscreen", "split-l", "split-r", "chevron-l", "chevron-r", "bolt",
        "equals", "folder", "globe", "doc", "table", "mail", "calendar", "bag", "sliders", "terminal", "note", "image", "music"]

    // Fond d'écran simplifié (dégradés de marque)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.dark ? "#1d1238" : "#ECE3FF" }
            GradientStop { position: 1; color: Theme.background }
        }
    }

    // ---------- En-tête : thème et accent ----------
    Surface {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space4 }
        height: 56
        kind: Surface.Glass
        Row {
            anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
            spacing: Theme.space3
            Label { text: "VinX OS"; font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold }
            Label { text: "Design system · Vinx.Controls"; level: Label.Secondary; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            anchors { right: parent.right; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
            spacing: Theme.space4
            Row {
                spacing: Theme.space2
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: ["transparent", "#6366F1", "#EC4899", "#F97316", "#16A34A", "#0EA5E9"]
                    Rectangle {
                        width: 20; height: 20; radius: 10
                        color: index === 0 ? (Theme.dark ? "#A855F7" : "#7C3AED") : modelData
                        border.width: Qt.colorEqual(Theme.accentOverride, modelData) ? 2 : 0
                        border.color: Theme.text
                        MouseArea { anchors.fill: parent; onClicked: Theme.accentOverride = modelData }
                    }
                }
            }
            SegmentedControl {
                model: ["Clair", "Sombre"]
                currentIndex: Theme.dark ? 1 : 0
                onActivated: (i) => Theme.dark = (i === 1)
            }
        }
    }

    // ---------- Contenu défilant ----------
    Flickable {
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: Theme.space4 }
        contentHeight: content.height
        clip: true

        Column {
            id: content
            width: parent.width
            spacing: Theme.space5

            component Section: Column {
                property alias title: t.text
                width: content.width
                spacing: Theme.space3
                Label { id: t; level: Label.Secondary; font.pixelSize: Theme.fsSm; font.weight: Font.DemiBold; font.letterSpacing: 0.6 }
            }

            Section {
                title: "BOUTONS"
                Row {
                    spacing: Theme.space3
                    Button { text: "Obtenir"; variant: Button.Primary; pill: true; onClicked: toast.show("Bouton principal") }
                    Button { text: "Installer"; variant: Button.Primary; iconName: "plus" }
                    Button { text: "Annuler" }
                    Button { text: "Discret"; variant: Button.Ghost }
                    Button { text: "Désactivé"; enabled: false }
                    IconButton { iconName: "sliders"; toolTip: "Paramètres" }
                    IconButton { iconName: "power"; toolTip: "Éteindre" }
                    IconButton { iconName: "search"; flat: true }
                }
            }

            Section {
                title: "CONTRÔLES"
                Row {
                    spacing: Theme.space5
                    Row { spacing: Theme.space2; Switch { id: sw1; checked: true } Label { text: sw1.checked ? "Activé" : "Désactivé"; height: 22 } }
                    Row { spacing: Theme.space2; Switch { id: sw2 } Label { text: sw2.checked ? "Activé" : "Désactivé"; height: 22 } }
                    Switch { enabled: false }
                    Column {
                        spacing: Theme.space1
                        Label { text: "Volume " + Math.round(vol.value * 100) + " %"; font.weight: Font.DemiBold; font.pixelSize: Theme.fsSm }
                        Slider { id: vol; width: 220; value: 0.6 }
                    }
                    SegmentedControl { model: ["Jour", "Semaine", "Mois"]; currentIndex: 1 }
                }
            }

            Section {
                title: "MENUS ET PANNEAUX"
                Row {
                    spacing: Theme.space3
                    Button { id: menuBtn; text: "Ouvrir un menu"; iconName: "grid"; onClicked: menu.toggle(menuBtn) }
                    Button { id: ccBtn; text: "Centre de contrôle"; iconName: "sliders"; onClicked: cc.toggle(ccBtn) }
                }
            }

            Section {
                title: "ICÔNES D'APPLICATIONS"
                Row {
                    spacing: Theme.space4
                    Repeater {
                        model: win.apps
                        Column {
                            spacing: Theme.space2
                            AppIcon { iconName: modelData[0]; colorTop: modelData[1]; colorBottom: modelData[2]; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: modelData[3]; font.pixelSize: Theme.fsSm; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }
                }
            }

            Section {
                title: "ICÔNES SYSTÈME (" + win.icons.length + ")"
                Flow {
                    width: parent.width
                    spacing: Theme.space2
                    Repeater {
                        model: win.icons
                        Surface {
                            kind: Surface.Sunken; elevation: 0
                            width: 84; height: 64; radius: Theme.radiusMd
                            Icon { name: modelData; width: 22; height: 22; color: Theme.text; anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 12 } }
                            Label { text: modelData; level: Label.Tertiary; font.pixelSize: Theme.fsXs; anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 } }
                        }
                    }
                }
            }

            Section {
                title: "TYPOGRAPHIE ET COULEURS"
                Row {
                    spacing: Theme.space6
                    Column {
                        spacing: Theme.space2
                        Label { text: "14:08"; font.pixelSize: Theme.fsDisplay; font.weight: Font.Light }
                        Label { text: "Titre — Inter 20"; font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold }
                        Label { text: "Texte courant — Inter 13" }
                        Label { text: "Texte secondaire"; level: Label.Secondary }
                        Label { text: "Texte tertiaire"; level: Label.Tertiary }
                    }
                    Grid {
                        columns: 4; spacing: Theme.space3
                        Repeater {
                            model: [["Accent", Theme.accent], ["Indigo", Theme.accent2], ["Succès", Theme.success], ["Alerte", Theme.warning],
                                    ["Danger", Theme.danger], ["Fenêtre", Theme.surfaceWindow], ["Creux", Theme.surfaceSunken], ["Fond", Theme.background]]
                            Column {
                                spacing: Theme.space1
                                Rectangle { width: 72; height: 44; radius: Theme.radiusMd; color: modelData[1]; border.width: 1; border.color: Theme.border }
                                Label { text: modelData[0]; font.pixelSize: Theme.fsXs; level: Label.Secondary }
                            }
                        }
                    }
                }
            }
            Item { width: 1; height: Theme.space5 }
        }
    }

    // ---------- Couche des popovers ----------
    Item {
        anchors.fill: parent

        Menu {
            id: menu
            model: [
                { header: "Fenêtre" },
                { text: "Réduire", shortcut: "Ctrl+Maj+↓" },
                { text: "Agrandir", shortcut: "Ctrl+Maj+↑" },
                { text: "Placer à gauche", iconName: "split-l", shortcut: "Ctrl+Maj+←" },
                { text: "Placer à droite", iconName: "split-r", shortcut: "Ctrl+Maj+→" },
                { separator: true },
                { text: "Thème sombre", checked: Theme.dark },
                { text: "Indisponible", enabled: false },
                { separator: true },
                { text: "Fermer", shortcut: "Ctrl+W" }
            ]
            onTriggered: (i, entry) => {
                if (entry.text === "Thème sombre") Theme.dark = !Theme.dark
                toast.show(entry.text)
            }
        }

        Popover {
            id: cc
            padding: Theme.space3
            Column {
                spacing: Theme.space3
                Grid {
                    columns: 2; spacing: Theme.space2
                    Tile { id: t1; iconName: checked ? "wifi" : "wifi-off"; title: "Wi-Fi"; subtitle: checked ? "Maison" : "Désactivé"; checked: true; onClicked: checked = !checked }
                    Tile { id: t2; iconName: "bluetooth"; title: "Bluetooth"; subtitle: checked ? "Activé" : "Désactivé"; checked: true; onClicked: checked = !checked }
                    Tile { iconName: checked ? "bell-off" : "bell"; title: "Concentration"; subtitle: checked ? "Ne pas déranger" : "Désactivé"; onClicked: checked = !checked }
                    Tile { iconName: Theme.dark ? "moon" : "sun"; title: "Apparence"; subtitle: Theme.dark ? "Sombre" : "Clair"; checked: Theme.dark; onClicked: Theme.dark = !Theme.dark }
                }
                Column {
                    spacing: 6
                    Label { text: "Luminosité"; font.weight: Font.DemiBold; font.pixelSize: Theme.fsSm }
                    Row { spacing: Theme.space2; Icon { name: "brightness"; color: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter } Slider { width: 290; value: 0.8 } }
                }
                Column {
                    spacing: 6
                    Label { text: "Son"; font.weight: Font.DemiBold; font.pixelSize: Theme.fsSm }
                    Row { spacing: Theme.space2; Icon { name: vol.value > 0 ? "volume" : "volume-off"; color: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter } Slider { width: 290; value: vol.value; onMoved: (v) => vol.value = v } }
                }
            }
        }
    }

    // Notification de démonstration
    Surface {
        id: toast
        function show(msg) { toastText.text = msg; opacity = 1; hideTimer.restart() }
        anchors { right: parent.right; bottom: parent.bottom; margins: Theme.space4 }
        width: 280; height: 52
        kind: Surface.Strong; elevation: 2
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }
        Row {
            anchors { left: parent.left; leftMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            spacing: Theme.space3
            AppIcon { size: 30; iconName: "sliders"; colorTop: "#8A93A6"; colorBottom: "#565E70" }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: "Action"; font.weight: Font.DemiBold }
                Label { id: toastText; level: Label.Secondary; font.pixelSize: Theme.fsSm }
            }
        }
        Timer { id: hideTimer; interval: 2500; onTriggered: toast.opacity = 0 }
    }
}
