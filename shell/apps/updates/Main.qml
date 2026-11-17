import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell

// Mises à jour de VinX OS (ADR 0026) : versions, mises à jour disponibles (Debian, bureau VinX,
// applications), historique et réglages. L'installation passe par /usr/lib/vinx/vinx-update.
Window {
    id: win
    width: 920; height: 640
    minimumWidth: 720; minimumHeight: 480
    visible: true
    title: qsTr("Mises à jour")
    color: Theme.surfaceWindow
    AppearanceSync {}

    property string startPage: ""
    readonly property var pages: [
        { id: "overview", title: qsTr("Vue d'ensemble"), icon: "restart" },
        { id: "history", title: qsTr("Historique"), icon: "list" },
        { id: "settings", title: qsTr("Réglages"), icon: "sliders" }
    ]
    property string page: pages.some(p => p.id === startPage) ? startPage : "overview"
    readonly property var versions: Updates.versions()
    property var history: []
    readonly property int rev: Preferences.revision
    function n(count, one, many) { return count + " " + (count > 1 ? many : one) }
    // « 2026-11-17 21:37 » → « 17/11/2026 21:37 »
    function day(d) { const m = /^(\d+)-(\d+)-(\d+) (.*)$/.exec(d || ""); return m ? m[3] + "/" + m[2] + "/" + m[1] + " " + m[4] : d }
    function on(k, def) { rev; const v = Preferences.value(k, def); return v === true || v === "true" }

    // Paquets du bureau VinX parmi les mises à jour Debian (dépôt APT VinX).
    readonly property var desktopUpdates: Updates.system.filter(p => /^vinx-/.test(p.name))
    readonly property var debianUpdates: Updates.system.filter(p => !/^vinx-/.test(p.name))

    Component.onCompleted: { Updates.check(); history = Updates.history() }
    Connections { target: Updates; function onFinished() { win.history = Updates.history() } }

    // ---------- Barre latérale ----------
    Rectangle {
        id: sidebar
        width: 210
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        color: Theme.surfaceSunken
        Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.border }
        Column {
            anchors { fill: parent; margins: Theme.space3; topMargin: Theme.space5 }
            spacing: 2
            Repeater {
                model: win.pages
                Rectangle {
                    required property var modelData
                    width: parent.width; height: 32
                    radius: Theme.radiusSm
                    color: win.page === modelData.id ? Theme.surfaceActive : nav.containsMouse ? Theme.surfaceHover : "transparent"
                    Row {
                        anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                        spacing: Theme.space2
                        Icon { name: modelData.icon; color: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: modelData.title; font.weight: win.page === modelData.id ? Font.DemiBold : Font.Normal }
                    }
                    MouseArea { id: nav; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = modelData.id }
                    Accessible.role: Accessible.PageTab
                    Accessible.name: modelData.title
                }
            }
        }
    }

    Flickable {
        anchors { left: sidebar.right; right: parent.right; top: parent.top; bottom: parent.bottom }
        contentHeight: content.height + Theme.space6 * 2
        clip: true
        Column {
            id: content
            x: Theme.space6; y: Theme.space6
            width: parent.width - Theme.space6 * 2
            spacing: Theme.space4

            // ---------- Vue d'ensemble ----------
            Column {
                visible: win.page === "overview"
                width: parent.width
                spacing: Theme.space5

                Row {
                    spacing: Theme.space4
                    width: parent.width
                    Rectangle {
                        width: 60; height: 60; radius: 16
                        color: "#06130D"
                        Icon { anchors.centerIn: parent; name: "vinx"; width: 36; height: 26; color: Theme.logo }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 60 - statusPill.width - Theme.space4 * 2
                        spacing: 2
                        Label {
                            objectName: "versionTitle"
                            text: "VinX OS " + (win.versions.vinxOs || "")
                            font.pixelSize: 24; font.weight: Font.DemiBold
                        }
                        Label {
                            width: parent.width
                            elide: Text.ElideRight
                            level: Label.Secondary
                            text: [qsTr("Bureau VinX %1").arg(win.versions.desktop),
                                   win.versions.debian ? qsTr("Debian %1").arg(win.versions.debian) : "",
                                   qsTr("noyau %1").arg(win.versions.kernel)].filter(s => s).join(" · ")
                        }
                    }
                    Rectangle {
                        id: statusPill
                        anchors.verticalCenter: parent.verticalCenter
                        height: 28; radius: 14
                        width: pillRow.implicitWidth + Theme.space4 * 2
                        color: Theme.surfaceSunken
                        border.width: 1; border.color: Theme.border
                        Row {
                            id: pillRow
                            anchors.centerIn: parent
                            spacing: Theme.space2
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: Updates.count > 0 ? Theme.warning : Theme.success
                            }
                            Label {
                                objectName: "statusText"
                                font.pixelSize: Theme.fsSm; font.weight: Font.DemiBold
                                text: Updates.applying ? qsTr("Installation… %1 %").arg(Math.max(0, Updates.progress))
                                    : Updates.checking ? qsTr("Recherche…")
                                    : Updates.count > 0 ? win.n(Updates.count, qsTr("mise à jour disponible"), qsTr("mises à jour disponibles"))
                                    : qsTr("Système à jour")
                            }
                        }
                    }
                }

                Row {
                    spacing: Theme.space3
                    Button {
                        text: qsTr("Tout mettre à jour")
                        variant: Button.Primary
                        enabled: Updates.count > 0 && !Updates.applying && !Updates.checking
                        onClicked: Updates.applyAll()
                    }
                    Button {
                        text: qsTr("Rechercher maintenant")
                        enabled: !Updates.applying && !Updates.checking
                        onClicked: Updates.check()
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        level: Label.Tertiary; font.pixelSize: Theme.fsSm
                        text: Updates.lastCheck.getTime() ? qsTr("Dernière recherche : %1").arg(Updates.lastCheck.toLocaleString(Qt.locale(), "dddd HH:mm"))
                                                          : Updates.status
                    }
                }

                // Groupes : bureau VinX, système Debian, applications.
                Rectangle {
                    width: parent.width
                    height: groups.height
                    radius: Theme.radiusMd
                    color: "transparent"
                    border.width: 1; border.color: Theme.border
                    visible: Updates.count > 0
                    Column {
                        id: groups
                        width: parent.width
                        Repeater {
                            model: [
                                { title: qsTr("Bureau VinX"), tint: Theme.accent, list: win.desktopUpdates,
                                  detail: qsTr("Barre, dock, Paramètres et applications VinX") },
                                { title: qsTr("Système Debian"), tint: "#2E9BFF", list: win.debianUpdates,
                                  detail: win.n(win.debianUpdates.length, qsTr("paquet"), qsTr("paquets")) + qsTr(" du système") },
                                { title: qsTr("Applications"), tint: "#FFB21E", list: Updates.apps,
                                  detail: Updates.apps.map(a => a.name).slice(0, 4).join(", ") }
                            ].filter(g => g.list.length > 0)
                            Item {
                                required property var modelData
                                required property int index
                                width: groups.width; height: 58
                                Rectangle { visible: index > 0; width: parent.width; height: 1; color: Theme.border }
                                Rectangle {
                                    id: tile
                                    x: Theme.space4; anchors.verticalCenter: parent.verticalCenter
                                    width: 32; height: 32; radius: 9
                                    color: Theme.surfaceSunken; border.width: 1; border.color: Theme.border
                                    Rectangle { width: 10; height: 10; radius: 5; color: modelData.tint; anchors { right: parent.right; bottom: parent.bottom; margins: -2 } }
                                }
                                Column {
                                    anchors { left: tile.right; leftMargin: Theme.space3; right: count.left; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
                                    Label { text: modelData.title; font.weight: Font.DemiBold }
                                    Label { text: modelData.detail; level: Label.Tertiary; font.pixelSize: Theme.fsSm; width: parent.width; elide: Text.ElideRight }
                                }
                                Label {
                                    id: count
                                    anchors { right: parent.right; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                                    level: Label.Secondary; font.pixelSize: Theme.fsSm
                                    text: modelData.list.length === 1 && modelData.list[0].from
                                        ? modelData.list[0].from + " → " + modelData.list[0].version
                                        : win.n(modelData.list.length, qsTr("mise à jour"), qsTr("mises à jour"))
                                }
                            }
                        }
                    }
                }

                Label {
                    visible: Updates.count === 0 && !Updates.checking
                    width: parent.width
                    wrapMode: Text.WordWrap
                    level: Label.Secondary
                    text: qsTr("Tout est à jour : système Debian, bureau VinX et applications.")
                }
                Label {
                    visible: !Updates.packageKitAvailable
                    width: parent.width; wrapMode: Text.WordWrap
                    level: Label.Tertiary; font.pixelSize: Theme.fsSm
                    text: qsTr("PackageKit est absent : seules les applications Flathub peuvent être mises à jour ici.")
                }
            }

            // ---------- Historique ----------
            Column {
                visible: win.page === "history"
                width: parent.width
                spacing: 0
                Label { text: qsTr("Historique"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; bottomPadding: Theme.space3 }
                Repeater {
                    model: win.history
                    Item {
                        required property var modelData
                        width: parent.width; height: 56
                        Column {
                            anchors { left: parent.left; right: when.left; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                            Label {
                                font.weight: Font.DemiBold
                                text: [modelData.upgraded ? win.n(modelData.upgraded, qsTr("mis à jour"), qsTr("mis à jour")) : "",
                                       modelData.installed ? win.n(modelData.installed, qsTr("installé"), qsTr("installés")) : "",
                                       modelData.removed ? win.n(modelData.removed, qsTr("supprimé"), qsTr("supprimés")) : ""].filter(s => s).join(" · ")
                            }
                            Label { text: modelData.packages; level: Label.Tertiary; font.pixelSize: Theme.fsSm; width: parent.width; elide: Text.ElideRight }
                        }
                        Label { id: when; anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: win.day(modelData.date); level: Label.Secondary; font.pixelSize: Theme.fsSm }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
                    }
                }
                Label { visible: win.history.length === 0; text: qsTr("Aucune opération enregistrée pour l'instant."); level: Label.Secondary }
            }

            // ---------- Réglages ----------
            Column {
                visible: win.page === "settings"
                width: parent.width
                Label { text: qsTr("Réglages"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; bottomPadding: Theme.space3 }
                Repeater {
                    model: [
                        { key: "updates/autoCheck", def: true, title: qsTr("Rechercher automatiquement"),
                          description: qsTr("Toutes les 6 heures ; une notification signale les mises à jour disponibles.") },
                        { key: "updates/autoApps", def: false, title: qsTr("Mettre à jour les applications automatiquement"),
                          description: qsTr("Applications Flathub, en arrière-plan et sans mot de passe. Le système reste à votre initiative.") }
                    ]
                    Item {
                        required property var modelData
                        width: parent.width
                        height: Math.max(56, texts.implicitHeight + Theme.space3 * 2)
                        Column {
                            id: texts
                            anchors { left: parent.left; right: sw.left; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                            Label { text: modelData.title; width: parent.width }
                            Label { text: modelData.description; level: Label.Secondary; font.pixelSize: Theme.fsSm; width: parent.width; wrapMode: Text.WordWrap }
                        }
                        Switch {
                            id: sw
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            checked: win.on(modelData.key, modelData.def)
                            onToggled: (c) => Preferences.setValue(modelData.key, c)
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
                    }
                }
            }
        }
    }
}
