import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell
import QtQuick.Dialogs

// Paramètres de VinX OS. Les réglages sont enregistrés dans les préférences partagées :
// le shell les applique immédiatement.
Window {
    id: win
    width: 940; height: 680
    minimumWidth: 760; minimumHeight: 480
    visible: true
    title: qsTr("Paramètres")
    color: Theme.surfaceWindow

    property string startPage: ""
    AppearanceSync {}

    readonly property int rev: Preferences.revision
    // Réglages KDE (kreadconfig6 / kwriteconfig6) : groupes imbriqués « A/B ».
    function kread(file, groups, key, def) {
        const args = ["--file", file]
        groups.split("/").forEach(g => { args.push("--group"); args.push(g) })
        args.push("--key"); args.push(key); args.push("--default"); args.push(String(def))
        return Session.capture("kreadconfig6", args).trim() || String(def)
    }
    function kwrite(file, groups, key, value) {
        const args = ["--file", file]
        groups.split("/").forEach(g => { args.push("--group"); args.push(g) })
        args.push("--key"); args.push(key); args.push(String(value))
        Session.capture("kwriteconfig6", args)
    }
    function pref(key, def) { rev; return Preferences.value(key, def) }
    function on(key, def) { const v = pref(key, def); return v === true || v === "true" }

    readonly property var pages: [
        { id: "appearance", title: qsTr("Apparence"), icon: "sun", section: qsTr("Personnalisation") },
        { id: "wallpaper", title: qsTr("Fond d'écran"), icon: "image", section: qsTr("Personnalisation") },
        { id: "desktop", title: qsTr("Bureau"), icon: "grid", section: qsTr("Personnalisation") },
        { id: "dock", title: qsTr("Dock"), icon: "folder", section: qsTr("Personnalisation") },
        { id: "notifications", title: qsTr("Notifications"), icon: "bell", section: qsTr("Personnalisation") },
        { id: "office", title: qsTr("Bureautique"), icon: "doc", section: qsTr("Personnalisation") },
        { id: "displays", title: qsTr("Écrans"), icon: "monitor", section: qsTr("Matériel") },
        { id: "sound", title: qsTr("Son"), icon: "volume", section: qsTr("Matériel") },
        { id: "power", title: qsTr("Énergie"), icon: "bolt", section: qsTr("Matériel") },
        { id: "network", title: qsTr("Réseau"), icon: "globe", section: qsTr("Matériel") },
        { id: "printers", title: qsTr("Imprimantes"), icon: "printer", section: qsTr("Matériel") },
        { id: "drivers", title: qsTr("Pilotes"), icon: "chip", section: qsTr("Matériel") },
        { id: "accessibility", title: qsTr("Accessibilité"), icon: "eye", section: qsTr("Système") },
        { id: "keyboard", title: qsTr("Clavier"), icon: "keyboard", section: qsTr("Système") },
        { id: "datetime", title: qsTr("Date et heure"), icon: "calendar", section: qsTr("Système") },
        { id: "users", title: qsTr("Utilisateurs"), icon: "user", section: qsTr("Système") },
        { id: "backup", title: qsTr("Sauvegarde"), icon: "drive", section: qsTr("Système") },
        { id: "troubleshoot", title: qsTr("Dépannage"), icon: "shield", section: qsTr("Système") },
        { id: "updates", title: qsTr("Mises à jour"), icon: "restart", section: qsTr("Système") },
        { id: "about", title: qsTr("À propos"), icon: "info", section: qsTr("Système") }
    ]
    property string page: pages.some(p => p.id === startPage) ? startPage : "appearance"

    // ---------- Barre latérale ----------
    Rectangle {
        id: sidebar
        width: 220
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        color: Theme.surfaceSunken
        Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.border }
        Label { id: sideTitle; text: qsTr("Paramètres"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; height: 40; x: Theme.space3 + Theme.space2; y: Theme.space4 }
        ListView {
            anchors { top: sideTitle.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; margins: Theme.space3; topMargin: 0 }
            clip: true
            spacing: 1
            boundsBehavior: Flickable.StopAtBounds
            model: win.pages
            section.property: "section"
            section.delegate: Label {
                required property string section
                text: section.toUpperCase(); level: Label.Tertiary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.6
                height: 28; leftPadding: Theme.space2; verticalAlignment: Text.AlignBottom; bottomPadding: 4
            }
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width; height: 30
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
                    description: String(win.pref("appearance/accent", "")) === "auto"
                        ? qsTr("Automatique : %1, d'après le fond d'écran.").arg(Theme.accentEntry.name)
                        : qsTr("Boutons principaux, éléments actifs, sélection et logo du fond « VinX Logo ».")
                }
                Flow {
                    id: accentPicker
                    width: parent.width
                    spacing: Theme.space1
                    bottomPadding: Theme.space4
                    readonly property string chosen: { const v = String(win.pref("appearance/accent", "")); return v === "" ? Theme.accents[0].id : v }
                    Repeater {
                        model: Theme.accents.concat([{ id: "auto", name: qsTr("Automatique"), fill: "" }])
                        Column {
                            required property var modelData
                            readonly property bool current: accentPicker.chosen === modelData.id
                            width: 66
                            spacing: Theme.space1
                            Rectangle {
                                id: chip
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 36; height: 36; radius: 18
                                color: parent.modelData.fill !== "" ? parent.modelData.fill : Theme.surfaceSunken
                                border.width: 1
                                border.color: Qt.rgba(0, 0, 0, 0.12)
                                // « Automatique » : quatre pastilles du nuancier.
                                Grid {
                                    visible: chip.parent.modelData.id === "auto"
                                    anchors.centerIn: parent
                                    columns: 2
                                    spacing: 2
                                    Repeater {
                                        model: ["lagon", "ambre", "framboise", "vert"]
                                        Rectangle {
                                            required property string modelData
                                            width: 11; height: 11; radius: 5.5
                                            color: Theme.accents.find(a => a.id === modelData).fill
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 44; height: 44; radius: 22
                                    color: "transparent"
                                    border.width: 2
                                    border.color: Theme.text
                                    visible: chip.parent.current
                                }
                                Accessible.role: Accessible.RadioButton
                                Accessible.name: chip.parent.modelData.name
                                Accessible.checked: chip.parent.current
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Preferences.setValue("appearance/accent", chip.parent.modelData.id)
                                }
                            }
                            Label {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: parent.modelData.name
                                font.pixelSize: Theme.fsXs
                                level: parent.current ? Label.Primary : Label.Secondary
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            // Bureautique (ADR 0029)
            Column {
                visible: win.page === "office"
                width: parent.width
                onVisibleChanged: if (visible) Office.refresh()
                SettingsRow {
                    title: qsTr("Format des nouveaux documents")
                    description: Office.format === "msoffice"
                        ? qsTr("Word (.docx), Excel (.xlsx), PowerPoint (.pptx) : s'ouvrent partout, sans conversion.")
                        : qsTr("OpenDocument (.odt, .ods, .odp) : format libre et ouvert de LibreOffice.")
                    SegmentedControl {
                        objectName: "officeFormat"
                        model: [qsTr("Microsoft Office"), qsTr("OpenDocument")]
                        currentIndex: Office.format === "odf" ? 1 : 0
                        onActivated: (i) => Office.setFormat(i === 0 ? "msoffice" : "odf")
                    }
                }
                Label {
                    visible: Office.libreOfficeInstalled && Office.libreOfficeRunning()
                    width: parent.width; wrapMode: Text.WordWrap; topPadding: Theme.space2
                    level: Label.Secondary; font.pixelSize: Theme.fsSm
                    text: qsTr("LibreOffice est ouvert : fermez-le pour que le changement soit pris en compte.")
                }
                SettingsRow {
                    title: qsTr("Polices compatibles Microsoft Office")
                    description: Office.missingFonts.length === 0
                        ? qsTr("Installées : les documents gardent la même mise en page que sous Word et Excel (Calibri, Cambria, Arial, Times New Roman…).")
                        : qsTr("Manquantes : %1. Sans elles, la mise en page des documents Word peut changer.").arg(Office.missingFonts.join(", "))
                    Button {
                        visible: Office.missingFonts.length > 0
                        text: qsTr("Installer")
                        variant: Button.Primary
                        enabled: !DebianPackages.busy
                        onClicked: DebianPackages.installPackages(["fonts-crosextra-carlito", "fonts-crosextra-caladea", "fonts-liberation"], qsTr("Polices compatibles"))
                    }
                }
                Connections { target: DebianPackages; function onFinished() { Office.refresh() } }
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
                        readonly property bool current: String(win.pref("desktop/wallpaper", "/usr/share/wallpapers/VinX-Logo/contents/images/3840x2160.png")) === modelData.path
                        spacing: Theme.space2
                        Rectangle {
                            width: 200; height: 112; radius: Theme.radiusMd
                            color: Theme.surfaceSunken
                            border.width: parent.current ? 2 : 1
                            border.color: parent.current ? Theme.accentForeground : Theme.border
                            // « VinX Logo » : aperçu en direct, à la couleur d'accent.
                            readonly property var logoMatch: /\/VinX-Logo(-Sombre)?\//.exec(modelData.path)
                            LogoWallpaper {
                                anchors { fill: parent; margins: 3 }
                                visible: parent.logoMatch !== null
                                dark: parent.logoMatch !== null && parent.logoMatch[1] !== undefined ? true : Theme.dark
                            }
                            Image {
                                anchors { fill: parent; margins: 3 }
                                visible: parent.logoMatch === null
                                source: parent.logoMatch === null ? "file://" + modelData.preview : ""
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
                // Bureaux virtuels (ADR 0030) : nombre et noms, sans le module KDE.
                SettingsRow {
                    title: qsTr("Bureaux virtuels")
                    description: qsTr("Plusieurs bureaux pour ranger vos fenêtres (Ctrl + Méta + ← / → pour passer de l'un à l'autre).")
                    Row {
                        spacing: Theme.space2
                        Button { text: "−"; enabled: Tasks.backend.desktopCount > 1; onClicked: Tasks.backend.removeDesktop() }
                        Label { objectName: "desktopCount"; text: Tasks.backend.desktopCount; width: 24; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter; font.weight: Font.DemiBold }
                        Button { text: "+"; enabled: Tasks.backend.desktopCount < 6; onClicked: Tasks.backend.addDesktop() }
                    }
                }
                Repeater {
                    model: Tasks.backend.desktopNames || []
                    SettingsRow {
                        required property string modelData
                        required property int index
                        title: qsTr("Nom du bureau %1").arg(index + 1)
                        Rectangle {
                            width: 220; height: 32; radius: Theme.radiusSm
                            color: Theme.surfaceSunken
                            border.width: nameField.activeFocus ? 2 : 1
                            border.color: nameField.activeFocus ? Theme.accentForeground : Theme.border
                            TextInput {
                                id: nameField
                                anchors { fill: parent; leftMargin: Theme.space2; rightMargin: Theme.space2 }
                                verticalAlignment: TextInput.AlignVCenter
                                text: modelData
                                color: Theme.text
                                font.pixelSize: Theme.fsMd
                                selectByMouse: true
                                onEditingFinished: if (text.trim() && text !== modelData) Tasks.backend.renameDesktop(index, text.trim())
                            }
                        }
                    }
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
                SettingsRow {
                    title: qsTr("Position")
                    SegmentedControl {
                        model: [qsTr("En bas"), qsTr("À gauche")]
                        currentIndex: String(win.pref("dock/position", "bottom")) === "left" ? 1 : 0
                        onActivated: (i) => Preferences.setValue("dock/position", i === 1 ? "left" : "bottom")
                    }
                }
                SettingsRow { title: qsTr("Agrandissement au survol"); Switch { checked: win.on("dock/magnify", true); onToggled: (c) => Preferences.setValue("dock/magnify", c) } }
                SettingsRow {
                    title: qsTr("Masquer automatiquement")
                    description: qsTr("Le dock réapparaît quand le pointeur touche le bas de l'écran.")
                    Switch { checked: win.on("dock/autohide", false); onToggled: (c) => Preferences.setValue("dock/autohide", c) }
                }
            }

            // Barre supérieure (page Bureau)
            Column {
                visible: win.page === "desktop"
                width: parent.width
                Label { text: qsTr("BARRE SUPÉRIEURE"); level: Label.Secondary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.8; height: 32; verticalAlignment: Text.AlignBottom }
                SettingsRow { title: qsTr("Afficher la date"); Switch { checked: win.on("topbar/showDate", true); onToggled: (c) => Preferences.setValue("topbar/showDate", c) } }
                SettingsRow {
                    title: qsTr("Pourcentage de batterie")
                    description: qsTr("Sinon, affiché seulement sous 20 %.")
                    Switch { checked: win.on("topbar/batteryPercent", false); onToggled: (c) => Preferences.setValue("topbar/batteryPercent", c) }
                }
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

            // Écrans
            DisplaysPage { visible: win.page === "displays"; width: parent.width }

            // Énergie (powerdevil + power-profiles-daemon)
            Column {
                id: power
                visible: win.page === "power"
                width: parent.width
                property int prev: 0
                property string profile: ""
                onVisibleChanged: if (visible) { prev++; profile = Session.capture("powerprofilesctl", ["get"]).trim() }
                function reload() { Session.launch("busctl", ["--user", "call", "org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement", "org.kde.Solid.PowerManagement", "refreshStatus"]) }
                // Même réglage sur secteur et sur batterie, pour rester simple.
                function setIdle(group, enableKey, timeKey, minutes) {
                    for (const src of ["AC", "Battery", "LowBattery"]) {
                        win.kwrite("powerdevilrc", src + "/" + group, enableKey, minutes > 0 ? (enableKey === "AutoSuspendAction" ? 1 : "true") : (enableKey === "AutoSuspendAction" ? 0 : "false"))
                        if (minutes > 0) win.kwrite("powerdevilrc", src + "/" + group, timeKey, minutes * 60)
                    }
                    reload(); prev++
                }
                function idleIndex(group, enableKey, timeKey, values) {
                    prev
                    const on = win.kread("powerdevilrc", "AC/" + group, enableKey, enableKey === "AutoSuspendAction" ? 1 : "true")
                    if (on === "false" || on === "0") return values.length - 1
                    const m = Number(win.kread("powerdevilrc", "AC/" + group, timeKey, values[0] * 60)) / 60
                    const i = values.indexOf(m)
                    return i < 0 ? 0 : i
                }
                SettingsRow {
                    title: qsTr("Éteindre l'écran après")
                    SegmentedControl {
                        readonly property var values: [5, 10, 30, 0]
                        model: ["5 min", "10 min", "30 min", qsTr("Jamais")]
                        currentIndex: power.idleIndex("Display", "TurnOffDisplayWhenIdle", "TurnOffDisplayIdleTimeoutSec", values)
                        onActivated: (i) => power.setIdle("Display", "TurnOffDisplayWhenIdle", "TurnOffDisplayIdleTimeoutSec", values[i])
                    }
                }
                SettingsRow {
                    title: qsTr("Mettre en veille après")
                    SegmentedControl {
                        readonly property var values: [15, 30, 60, 0]
                        model: ["15 min", "30 min", "1 h", qsTr("Jamais")]
                        currentIndex: power.idleIndex("SuspendAndShutdown", "AutoSuspendAction", "AutoSuspendIdleTimeoutSec", values)
                        onActivated: (i) => power.setIdle("SuspendAndShutdown", "AutoSuspendAction", "AutoSuspendIdleTimeoutSec", values[i])
                    }
                }
                SettingsRow {
                    visible: power.profile !== ""
                    title: qsTr("Mode d'énergie")
                    description: qsTr("Économie : autonomie maximale. Performances : plus rapide, plus bruyant.")
                    SegmentedControl {
                        readonly property var values: ["power-saver", "balanced", "performance"]
                        model: [qsTr("Économie"), qsTr("Équilibré"), qsTr("Performances")]
                        currentIndex: Math.max(0, values.indexOf(power.profile))
                        onActivated: (i) => { Session.launch("powerprofilesctl", ["set", values[i]]); power.profile = values[i] }
                    }
                }
                SettingsRow {
                    visible: Battery.present
                    title: qsTr("Batterie")
                    Label { text: Battery.percentage + " %" + (Battery.charging ? qsTr(" · en charge") : ""); level: Label.Secondary }
                }
            }

            // Imprimantes
            PrintersPage { visible: win.page === "printers"; width: parent.width }

            // Pilotes
            DriversPage { visible: win.page === "drivers"; width: parent.width }

            // Dépannage
            TroubleshootPage { visible: win.page === "troubleshoot"; width: parent.width; onOpenPage: (id) => win.page = id }

            // Utilisateurs
            UsersPage { visible: win.page === "users"; width: parent.width }

            // Sauvegarde : instantanés du système (Timeshift)
            Column {
                id: backup
                visible: win.page === "backup"
                width: parent.width
                property bool enabledState: false
                function load() { enabledState = Session.capture("/usr/lib/vinx/vinx-snapshots", ["status"]).trim() === "enabled" }
                onVisibleChanged: if (visible) load()
                Timer { id: backupReload; interval: 4000; repeat: true; running: backup.visible; onTriggered: backup.load() }
                SettingsRow {
                    title: qsTr("Instantanés du système")
                    description: qsTr("Un instantané chaque jour et avant chaque mise à jour, pour revenir en arrière en cas de problème. Vos documents ne sont pas inclus.")
                    Switch {
                        checked: backup.enabledState
                        onToggled: (c) => Session.launch("pkexec", ["/usr/lib/vinx/vinx-snapshots", c ? "enable" : "disable"])
                    }
                }
                SettingsRow {
                    title: qsTr("Restaurer le système")
                    description: qsTr("Revenir à un instantané précédent (redémarrage nécessaire).")
                    Button { text: qsTr("Ouvrir…"); variant: Button.Secondary; enabled: backup.enabledState; onClicked: Session.launch("timeshift-launcher") }
                }
                SettingsRow {
                    title: qsTr("Sauvegarder vos documents")
                    description: qsTr("Copiez régulièrement votre dossier personnel sur un disque externe ou un service en ligne.")
                    Button { text: qsTr("Ouvrir Fichiers"); variant: Button.Ghost; onClicked: Session.launch("vinx-files") }
                }
            }

            // Réseau
            Column {
                visible: win.page === "network"
                onVisibleChanged: if (visible) NetConfig.refresh()
                Component.onCompleted: if (visible) NetConfig.refresh()
                width: parent.width
                SettingsRow {
                    title: qsTr("État")
                    Label { text: !Network.available ? qsTr("Indisponible") : Network.connected ? qsTr("Connecté · %1").arg(Network.connectionName) : qsTr("Déconnecté"); level: Label.Secondary }
                }
                WifiNetworks { width: parent.width; listHeight: 340; visible: Wifi.available; topPadding: Theme.space2; bottomPadding: Theme.space3 }
                SettingsRow {
                    visible: Bluetooth.available
                    title: qsTr("Bluetooth")
                    Switch { checked: Bluetooth.powered; onToggled: (c) => Bluetooth.powered = c }
                }
                // VPN et adresse IP fixe (ADR 0030), sans le module réseau de KDE.
                Item {
                    width: parent.width; height: 36
                    Label { text: qsTr("VPN"); level: Label.Secondary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.8; anchors.bottom: parent.bottom; anchors.bottomMargin: 4 }
                    Button { anchors { right: parent.right; bottom: parent.bottom } text: qsTr("Importer…"); variant: Button.Ghost; onClicked: vpnDialog.open() }
                }
                Label {
                    visible: NetConfig.vpns.length === 0
                    width: parent.width; wrapMode: Text.WordWrap; level: Label.Secondary; font.pixelSize: Theme.fsSm
                    text: qsTr("Aucun VPN. Importez le fichier fourni par votre entreprise ou votre fournisseur (WireGuard .conf, OpenVPN .ovpn).")
                }
                Repeater {
                    model: NetConfig.vpns
                    SettingsRow {
                        required property var modelData
                        title: modelData.name
                        description: modelData.kind + (modelData.active ? qsTr(" · connecté") : "")
                        Row {
                            spacing: Theme.space2
                            Button { text: qsTr("Supprimer"); variant: Button.Ghost; onClicked: NetConfig.removeVpn(modelData.name) }
                            Switch { checked: modelData.active; onToggled: (c) => NetConfig.setVpnActive(modelData.name, c) }
                        }
                    }
                }
                Label { visible: netMessage.text !== ""; id: netMessage; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: Theme.fsSm; topPadding: Theme.space2
                        property bool ok: true; color: ok ? Theme.accentForeground : Theme.danger }
                Connections { target: NetConfig; function onFinished(ok, msg) { netMessage.ok = ok; netMessage.text = msg } }
                FileDialog {
                    id: vpnDialog
                    title: qsTr("Importer un VPN")
                    nameFilters: [qsTr("Fichiers VPN (*.conf *.ovpn)")]
                    onAccepted: NetConfig.importVpn(String(selectedFile))
                }

                Label { text: qsTr("ADRESSE IP"); level: Label.Secondary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.8; height: 36; verticalAlignment: Text.AlignBottom; bottomPadding: 4; visible: NetConfig.activeConnection !== "" }
                SettingsRow {
                    visible: NetConfig.activeConnection !== ""
                    title: qsTr("Adresse de « %1 »").arg(NetConfig.activeConnection)
                    description: qsTr("Automatique dans presque tous les cas. Une adresse fixe sert à un serveur ou à une imprimante partagée.")
                    SegmentedControl {
                        model: [qsTr("Automatique"), qsTr("Fixe")]
                        currentIndex: ipForm.manual ? 1 : 0
                        onActivated: (i) => { if (i === 0) { ipForm.manual = false; NetConfig.setAutomaticIp() } else ipForm.manual = true }
                    }
                }
                Column {
                    id: ipForm
                    property bool manual: NetConfig.ipv4.manual === true
                    visible: manual && NetConfig.activeConnection !== ""
                    width: parent.width
                    spacing: Theme.space2
                    Repeater {
                        id: ipFields
                        model: [{ key: "address", label: qsTr("Adresse"), hint: "192.168.1.50" },
                                { key: "prefix", label: qsTr("Masque (longueur)"), hint: "24" },
                                { key: "gateway", label: qsTr("Passerelle"), hint: "192.168.1.1" },
                                { key: "dns", label: qsTr("Serveur DNS"), hint: "1.1.1.1" }]
                        SettingsRow {
                            required property var modelData
                            property alias value: field.text
                            title: modelData.label
                            Rectangle {
                                width: 200; height: 32; radius: Theme.radiusSm
                                color: Theme.surfaceSunken
                                border.width: field.activeFocus ? 2 : 1
                                border.color: field.activeFocus ? Theme.accentForeground : Theme.border
                                TextInput {
                                    id: field
                                    anchors { fill: parent; leftMargin: Theme.space2; rightMargin: Theme.space2 }
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: NetConfig.ipv4[modelData.key] !== undefined ? String(NetConfig.ipv4[modelData.key]) : ""
                                    color: Theme.text; font.pixelSize: Theme.fsMd; selectByMouse: true
                                    Label { visible: !field.text; text: modelData.hint; level: Label.Tertiary; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                    }
                    Button {
                        anchors.right: parent.right
                        text: qsTr("Enregistrer l'adresse")
                        variant: Button.Primary
                        onClicked: NetConfig.setManualIp(ipFields.itemAt(0).value, parseInt(ipFields.itemAt(1).value) || 24,
                                                         ipFields.itemAt(2).value, ipFields.itemAt(3).value)
                    }
                }
                SettingsRow {
                    title: qsTr("Réseaux d'entreprise (802.1X), proxy et cas particuliers")
                    description: qsTr("Réglages experts.")
                    Button { text: qsTr("Avancé…"); variant: Button.Ghost; onClicked: Session.launch("systemsettings", ["kcm_networkmanagement"]) }
                }
            }

            // Son
            Column {
                visible: win.page === "sound"
                width: parent.width
                onVisibleChanged: if (visible) Audio.refreshSinks()
                SettingsRow {
                    title: qsTr("Volume")
                    description: Audio.available ? qsTr("%1 %").arg(Math.round(Audio.volume * 100)) : qsTr("Indisponible")
                    Slider { width: 220; enabled: Audio.available; value: Audio.volume; onMoved: (v) => Audio.volume = v }
                }
                SettingsRow {
                    title: qsTr("Couper le son")
                    Switch { checked: Audio.muted; enabled: Audio.available; onToggled: (c) => Audio.muted = c }
                }
                Label { visible: Audio.sinks.length > 0; text: qsTr("SORTIE"); level: Label.Secondary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.8; height: 32; verticalAlignment: Text.AlignBottom }
                Repeater {
                    model: Audio.sinks
                    delegate: SettingsRow {
                        required property var modelData
                        title: modelData.name
                        Button {
                            text: modelData.isDefault ? qsTr("Utilisée") : qsTr("Utiliser")
                            variant: modelData.isDefault ? Button.Ghost : Button.Secondary
                            enabled: !modelData.isDefault
                            onClicked: Audio.setDefaultSink(modelData.id)
                        }
                    }
                }
            }

            // Date et heure (timedatectl ; les modifications passent par polkit)
            Column {
                id: dt
                visible: win.page === "datetime"
                width: parent.width
                property var info: ({})
                property var zones: []
                function load() {
                    const o = {}
                    Session.capture("timedatectl", ["show"]).split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) })
                    info = o
                    if (!zones.length) zones = Session.capture("timedatectl", ["list-timezones"]).split("\n").filter(z => z.indexOf("/") > 0)
                }
                onVisibleChanged: if (visible) load()
                Timer { id: dtReload; interval: 1500; onTriggered: dt.load() }
                SettingsRow {
                    title: qsTr("Réglage automatique")
                    description: qsTr("Synchronise l'heure par Internet (NTP).")
                    Switch {
                        checked: dt.info.NTP === "yes"
                        onToggled: (c) => { Session.launch("timedatectl", ["set-ntp", c ? "true" : "false"]); dtReload.restart() }
                    }
                }
                SettingsRow {
                    title: qsTr("Fuseau horaire")
                    description: dt.info.Timezone || qsTr("Inconnu")
                    Button { text: zonePicker.visible ? qsTr("Fermer") : qsTr("Changer…"); variant: Button.Secondary; onClicked: zonePicker.visible = !zonePicker.visible }
                }
                Column {
                    id: zonePicker
                    visible: false
                    width: parent.width
                    spacing: Theme.space2
                    Rectangle {
                        width: parent.width; height: 32; radius: Theme.radiusSm
                        color: Theme.surfaceSunken; border.width: 1; border.color: Theme.border
                        TextInput {
                            id: zoneFilter
                            anchors { fill: parent; leftMargin: Theme.space3; rightMargin: Theme.space3 }
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text; font.pixelSize: Theme.fsMd
                            Label { visible: !zoneFilter.text; text: qsTr("Filtrer (ex. Paris)"); level: Label.Tertiary; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                    ListView {
                        width: parent.width; height: 220; clip: true
                        model: dt.zones.filter(z => z.toLowerCase().indexOf(zoneFilter.text.toLowerCase()) >= 0)
                        delegate: MenuItem {
                            required property var modelData
                            width: ListView.view.width
                            text: modelData.replace(/_/g, " ")
                            checked: modelData === dt.info.Timezone
                            onTriggered: { Session.launch("timedatectl", ["set-timezone", modelData]); zonePicker.visible = false; dtReload.restart() }
                        }
                    }
                }
                SettingsRow {
                    title: qsTr("Format 24 heures")
                    Switch { checked: win.on("clock/24h", true); onToggled: (c) => Preferences.setValue("clock/24h", c) }
                }
            }

            // Mises à jour
            Column {
                visible: win.page === "updates"
                width: parent.width
                SettingsRow {
                    title: qsTr("Vérifier automatiquement")
                    description: qsTr("Toutes les 6 heures ; une notification signale les mises à jour disponibles.")
                    Switch { checked: win.on("updates/autoCheck", true); onToggled: (c) => Preferences.setValue("updates/autoCheck", c) }
                }
                SettingsRow {
                    title: qsTr("Mettre à jour les applications automatiquement")
                    description: qsTr("Les applications Flathub se mettent à jour en arrière-plan, sans mot de passe. Le système reste à votre initiative.")
                    Switch { checked: win.on("updates/autoApps", false); onToggled: (c) => Preferences.setValue("updates/autoApps", c) }
                }
                SettingsRow {
                    title: qsTr("Installer les mises à jour")
                    description: qsTr("Version de VinX OS, système Debian, bureau VinX et applications, avec l'historique.")
                    Button { text: qsTr("Ouvrir…"); variant: Button.Secondary; onClicked: Session.launch("vinx-updates") }
                }
            }

            // Accessibilité
            Column {
                visible: win.page === "accessibility"
                width: parent.width
                SettingsRow {
                    title: qsTr("Réduire les animations")
                    description: qsTr("Ouvre panneaux et menus sans transition.")
                    Switch { checked: win.on("accessibility/reduceMotion", false); onToggled: (c) => Preferences.setValue("accessibility/reduceMotion", c) }
                }
                SettingsRow {
                    title: qsTr("Taille du texte")
                    SegmentedControl {
                        readonly property var scales: [1.0, 1.15, 1.3]
                        model: [qsTr("Normale"), qsTr("Grande"), qsTr("Très grande")]
                        currentIndex: Math.max(0, scales.indexOf(Number(win.pref("accessibility/textScale", 1.0))))
                        onActivated: (i) => Preferences.setValue("accessibility/textScale", scales[i])
                    }
                }
            }

            // Clavier : raccourcis (source unique : Shortcuts.js)
            Column {
                visible: win.page === "keyboard"
                width: parent.width
                Repeater {
                    model: [
                        ["Méta", qsTr("Recherche")],
                        ["Méta + Espace", qsTr("Recherche")],
                        ["Méta + A", qsTr("Centre de contrôle")],
                        ["Méta + N", qsTr("Calendrier et notifications")],
                        ["Méta + L", qsTr("Verrouiller la session")],
                        ["Méta + W", qsTr("Vue d'ensemble des fenêtres")],
                        ["Méta + Tab", qsTr("Changer de fenêtre")],
                        ["Méta + ← / →", qsTr("Placer la fenêtre à gauche / à droite")],
                        ["Méta + ↑", qsTr("Agrandir la fenêtre")],
                        ["Ctrl + Méta + ← / →", qsTr("Espace de travail précédent / suivant")],
                        ["Échap", qsTr("Fermer le panneau ou le menu ouvert")]
                    ]
                    delegate: SettingsRow {
                        required property var modelData
                        title: modelData[1]
                        Label { text: modelData[0]; level: Label.Secondary }
                    }
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
                        title: qsTr("Version de VinX OS")
                        description: qsTr("Versions détaillées et mises à jour.")
                        Button { text: qsTr("Mises à jour…"); onClicked: Session.launch("vinx-updates") }
                    }
                }
            }
        }
    }
}
