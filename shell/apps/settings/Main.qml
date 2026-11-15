import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell

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
        { id: "displays", title: qsTr("Écrans"), icon: "grid", section: qsTr("Matériel") },
        { id: "sound", title: qsTr("Son"), icon: "volume", section: qsTr("Matériel") },
        { id: "power", title: qsTr("Énergie"), icon: "bolt", section: qsTr("Matériel") },
        { id: "network", title: qsTr("Réseau"), icon: "globe", section: qsTr("Matériel") },
        { id: "printers", title: qsTr("Imprimantes"), icon: "doc", section: qsTr("Matériel") },
        { id: "accessibility", title: qsTr("Accessibilité"), icon: "eye", section: qsTr("Système") },
        { id: "keyboard", title: qsTr("Clavier"), icon: "keyboard", section: qsTr("Système") },
        { id: "datetime", title: qsTr("Date et heure"), icon: "calendar", section: qsTr("Système") },
        { id: "users", title: qsTr("Utilisateurs"), icon: "home", section: qsTr("Système") },
        { id: "backup", title: qsTr("Sauvegarde"), icon: "drive", section: qsTr("Système") },
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
                    description: qsTr("Boutons principaux, éléments actifs et sélection.")
                    Row {
                        spacing: Theme.space2
                        Repeater {
                            model: ["", "#3B82C4", "#3E8460", "#B8693F", "#A8514F", "#6B6E76"]
                            Rectangle {
                                required property string modelData
                                readonly property bool current: String(win.pref("appearance/accent", "")) === modelData
                                width: 22; height: 22; radius: 11
                                color: modelData === "" ? (Theme.dark ? "#7358BD" : "#6548AE") : modelData
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
                        readonly property bool current: String(win.pref("desktop/wallpaper", "/usr/share/wallpapers/VinX-Biseau/contents/images/3840x2160.png")) === modelData.path
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

            // Écrans (kscreen-doctor)
            Column {
                id: displays
                visible: win.page === "displays"
                width: parent.width
                spacing: Theme.space2
                property var outputs: []
                function load() {
                    try { outputs = (JSON.parse(Session.capture("kscreen-doctor", ["-j"]) || "{}").outputs || []).filter(o => o.connected) }
                    catch (e) { outputs = [] }
                }
                onVisibleChanged: if (visible) load()
                Timer { id: displayReload; interval: 1500; onTriggered: displays.load() }
                Label { visible: displays.outputs.length === 0; text: qsTr("Réglage des écrans indisponible ici."); level: Label.Secondary }
                Repeater {
                    model: displays.outputs
                    delegate: Column {
                        id: out
                        required property var modelData
                        width: displays.width
                        readonly property var modes: {
                            // Une entrée par définition, à la meilleure fréquence.
                            const best = {}
                            for (const m of modelData.modes || []) {
                                const k = m.size.width + "×" + m.size.height
                                if (!best[k] || m.refreshRate > best[k].refreshRate) best[k] = m
                            }
                            return Object.values(best).sort((a, b) => b.size.width * b.size.height - a.size.width * a.size.height)
                        }
                        readonly property var current: (modelData.modes || []).find(m => m.id === modelData.currentModeId)
                        Label { text: modelData.name.toUpperCase(); level: Label.Secondary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.8; height: 32; verticalAlignment: Text.AlignBottom }
                        SettingsRow {
                            title: qsTr("Définition")
                            description: out.current ? qsTr("%1 × %2 à %3 Hz").arg(out.current.size.width).arg(out.current.size.height).arg(Math.round(out.current.refreshRate)) : ""
                            Button {
                                text: qsTr("Changer…"); variant: Button.Secondary
                                onClicked: modeMenu.visible = !modeMenu.visible
                            }
                        }
                        Flow {
                            id: modeMenu
                            visible: false
                            width: parent.width; spacing: Theme.space2
                            Repeater {
                                model: out.modes
                                delegate: Button {
                                    required property var modelData
                                    text: modelData.size.width + " × " + modelData.size.height
                                    variant: out.current && out.current.size.width === modelData.size.width && out.current.size.height === modelData.size.height ? Button.Primary : Button.Secondary
                                    onClicked: { Session.launch("kscreen-doctor", ["output." + out.modelData.name + ".mode." + modelData.id]); modeMenu.visible = false; displayReload.restart() }
                                }
                            }
                        }
                        SettingsRow {
                            title: qsTr("Taille du texte et des éléments")
                            description: qsTr("%1 %").arg(Math.round((out.modelData.scale || 1) * 100))
                            SegmentedControl {
                                readonly property var scales: [1, 1.25, 1.5, 2]
                                model: ["100 %", "125 %", "150 %", "200 %"]
                                currentIndex: Math.max(0, scales.indexOf(out.modelData.scale || 1))
                                onActivated: (i) => { Session.launch("kscreen-doctor", ["output." + out.modelData.name + ".scale." + scales[i]]); displayReload.restart() }
                            }
                        }
                    }
                }
                SettingsRow {
                    title: qsTr("Disposition, fréquence, orientation")
                    Button { text: qsTr("Ouvrir…"); variant: Button.Secondary; onClicked: Session.launch("systemsettings", ["kcm_kscreen"]) }
                }
            }

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

            // Imprimantes (CUPS)
            Column {
                id: printers
                visible: win.page === "printers"
                width: parent.width
                property var list: []
                onVisibleChanged: if (visible) list = Session.capture("lpstat", ["-e"]).split("\n").filter(l => l.trim())
                Label { visible: printers.list.length === 0; text: qsTr("Aucune imprimante. Les imprimantes réseau récentes sont généralement détectées automatiquement."); level: Label.Secondary; wrapMode: Text.WordWrap; width: parent.width; bottomPadding: Theme.space3 }
                Repeater {
                    model: printers.list
                    delegate: SettingsRow { required property string modelData; title: modelData.replace(/_/g, " ") }
                }
                SettingsRow {
                    title: qsTr("Ajouter ou configurer une imprimante")
                    Button { text: qsTr("Ouvrir…"); variant: Button.Secondary; onClicked: Session.launch("systemsettings", ["kcm_printer_manager"]) }
                }
            }

            // Utilisateurs
            Column {
                visible: win.page === "users"
                width: parent.width
                SettingsRow {
                    title: (Session.capture("getent", ["passwd", Session.userName]).split(":")[4] || "").split(",")[0] || Session.userName
                    description: qsTr("Votre compte · administrateur")
                    Button { text: qsTr("Changer le mot de passe…"); variant: Button.Secondary; onClicked: Session.launch("systemsettings", ["kcm_users"]) }
                }
                SettingsRow {
                    title: qsTr("Ajouter un utilisateur")
                    description: qsTr("Chaque personne a ses propres documents et réglages.")
                    Button { text: qsTr("Gérer…"); variant: Button.Secondary; onClicked: Session.launch("systemsettings", ["kcm_users"]) }
                }
                SettingsRow {
                    title: qsTr("Comptes en ligne")
                    description: qsTr("Google, Nextcloud… pour les fichiers et agendas.")
                    Button { text: qsTr("Gérer…"); variant: Button.Secondary; onClicked: Session.launch("systemsettings", ["kcm_kaccounts"]) }
                }
            }

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
                width: parent.width
                SettingsRow {
                    title: qsTr("État")
                    Label { text: !Network.available ? qsTr("Indisponible") : Network.connected ? qsTr("Connecté · %1").arg(Network.connectionName) : qsTr("Déconnecté"); level: Label.Secondary }
                }
                SettingsRow {
                    visible: Network.wireless
                    title: qsTr("Wi-Fi")
                    Switch { checked: Network.wirelessEnabled; onToggled: (c) => Network.wirelessEnabled = c }
                }
                SettingsRow {
                    visible: Bluetooth.available
                    title: qsTr("Bluetooth")
                    Switch { checked: Bluetooth.powered; onToggled: (c) => Bluetooth.powered = c }
                }
                SettingsRow {
                    title: qsTr("Réseaux, VPN et appareils Bluetooth")
                    description: qsTr("Choix du réseau Wi-Fi, mots de passe, VPN, appairage.")
                    Button { text: qsTr("Ouvrir…"); variant: Button.Secondary; onClicked: Session.launch("systemsettings", ["kcm_networkmanagement"]) }
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
                    title: qsTr("Installer les mises à jour")
                    description: qsTr("Système (Debian) et applications (Flathub), depuis le Store.")
                    Button { text: qsTr("Ouvrir…"); variant: Button.Secondary; onClicked: Session.launch("vinx-store", ["--page", "updates"]) }
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
                        title: qsTr("Réglages du matériel et du système")
                        description: qsTr("Écrans, réseau, imprimantes, comptes…")
                        Button { text: qsTr("Ouvrir…"); onClicked: Session.launch("systemsettings") }
                    }
                }
            }
        }
    }
}
