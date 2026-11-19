import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell
import "Catalog.js" as Catalog

// Store de VinX OS (ADR 0027) : vitrine avec rayons à gauche, « Sélection VinX », logiciels Debian
// et Flathub mélangés (badge de source ; Debian d'abord quand les deux existent), logos AppStream.
Window {
    id: win
    width: 1080; height: 720
    minimumWidth: 820; minimumHeight: 520
    visible: true
    title: qsTr("Store")
    color: Theme.surfaceWindow
    AppearanceSync {}

    // Page : "home", "search", "installed" ou "cat:<rayon>"
    property string startPage: ""
    property string startQuery: ""
    property string page: startPage === "search" ? "search" : startPage === "installed" ? "installed" : "home"
    // Logiciel mis en avant (tiré au sort à l'ouverture).
    readonly property var pick: Catalog.selection[Math.floor(Math.random() * Catalog.selection.length)]

    Component.onCompleted: {
        if (startPage === "updates") Session.launch("vinx-updates")
        DebianPackages.lookup(Catalog.packages())
        Flatpak.refreshAppstream()   // logos Flathub : catalogue téléchargé s'il manque ou date de plus d'un jour
        if (startQuery) {
            page = "search"
            query.text = startQuery.replace(/^debian:/, "")
        }
    }

    // Fiche affichable d'un logiciel du catalogue : Debian si le dépôt le connaît, sinon Flathub.
    function resolve(entry) {
        if (!entry) return null
        const deb = entry.pkg ? DebianPackages.catalog[entry.pkg] : undefined
        if (deb)
            return { source: "debian", name: entry.name, summary: entry.summary, package: entry.pkg, id: deb.id,
                     iconUrl: deb.iconUrl || "", icon: deb.icon || "", installed: deb.installed === true, tint: entry.tint }
        if (entry.flatpak && Flatpak.available)
            return { source: "flathub", name: entry.name, summary: entry.summary, id: entry.flatpak,
                     iconUrl: Flatpak.iconUrl(entry.flatpak), installed: Flatpak.installed.indexOf(entry.flatpak) >= 0, tint: entry.tint }
        return null
    }
    function resolveAll(entries) {
        DebianPackages.catalog; Flatpak.installed; Flatpak.iconsRevision   // dépendances de la liaison
        return entries.map(e => resolve(e)).filter(a => a !== null)
    }
    function showApp(a) { detail.open(a) }

    // ---------- Rayons ----------
    Rectangle {
        id: nav
        width: 220
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        color: Theme.surfaceSunken
        Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.border }
        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space3; topMargin: Theme.space5 }
            spacing: 2
            Label { text: qsTr("Store"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; leftPadding: Theme.space2; bottomPadding: Theme.space3 }
            Repeater {
                model: [
                    { id: "home", title: qsTr("À la une"), icon: "grid" },
                    { id: "search", title: qsTr("Rechercher"), icon: "search" },
                    { id: "installed", title: qsTr("Installées"), icon: "check" },
                    { id: "updates", title: qsTr("Mises à jour"), icon: "restart", count: Updates.count }
                ].concat([{ section: qsTr("Catégories") }]).concat(Catalog.categories.map(c => ({ id: "cat:" + c.id, title: c.name, tint: c.tint })))
                Item {
                    required property var modelData
                    width: parent.width
                    height: modelData.section ? 34 : 32
                    Label {
                        visible: !!modelData.section
                        anchors { left: parent.left; leftMargin: Theme.space2; bottom: parent.bottom; bottomMargin: 4 }
                        text: (modelData.section || "").toUpperCase(); level: Label.Tertiary; font.pixelSize: Theme.fsXs; font.letterSpacing: 0.6
                    }
                    Rectangle {
                        visible: !modelData.section
                        anchors.fill: parent
                        radius: Theme.radiusSm
                        color: win.page === modelData.id ? Theme.surfaceWindow : navMouse.containsMouse ? Theme.surfaceHover : "transparent"
                        Row {
                            anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                            spacing: Theme.space2
                            Icon { visible: !!modelData.icon; name: modelData.icon || "grid"; color: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle { visible: !modelData.icon; width: 12; height: 12; radius: 4; color: modelData.tint || "transparent"; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: modelData.title || ""; font.weight: win.page === modelData.id ? Font.DemiBold : Font.Normal }
                        }
                        Label {
                            visible: (modelData.count || 0) > 0
                            anchors { right: parent.right; rightMargin: Theme.space2; verticalCenter: parent.verticalCenter }
                            text: modelData.count || ""; level: Label.Tertiary; font.pixelSize: Theme.fsSm
                        }
                        MouseArea {
                            id: navMouse
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: modelData.id === "updates" ? Session.launch("vinx-updates") : win.page = modelData.id
                        }
                        Accessible.role: Accessible.PageTab
                        Accessible.name: modelData.title || ""
                    }
                }
            }
        }
        // Installation en cours
        Column {
            visible: Flatpak.busy || DebianPackages.busy
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.space4 }
            spacing: 6
            readonly property int pct: Flatpak.busy ? Flatpak.progress : DebianPackages.progress
            Label { text: Flatpak.busy ? Flatpak.task : DebianPackages.task; font.pixelSize: Theme.fsSm; width: parent.width; elide: Text.ElideRight }
            Rectangle {
                width: parent.width; height: 5; radius: 2.5; color: Theme.surfaceActive
                Rectangle { height: parent.height; radius: 2.5; color: Theme.accent; width: parent.width * Math.max(0.04, Math.max(0, parent.parent.pct) / 100) }
            }
        }
    }

    Flickable {
        id: scroller
        anchors { left: nav.right; right: parent.right; top: parent.top; bottom: parent.bottom }
        contentHeight: content.height + Theme.space6 * 2
        clip: true
        Column {
            id: content
            x: Theme.space6; y: Theme.space5
            width: scroller.width - Theme.space6 * 2
            spacing: Theme.space5
            readonly property int cols: Math.max(1, Math.floor((width + Theme.space3) / (250 + Theme.space3)))
            readonly property real cardWidth: (width - (cols - 1) * Theme.space3) / cols

            // Champ de recherche (toutes les pages sauf la fiche)
            Rectangle {
                width: parent.width; height: 40
                radius: Theme.radiusMd
                color: Theme.surfaceSunken
                border.width: query.activeFocus ? 2 : 1
                border.color: query.activeFocus ? Theme.accentForeground : Theme.border
                Icon { id: glass; name: "search"; color: Theme.textSecondary; anchors { left: parent.left; leftMargin: Theme.space3; verticalCenter: parent.verticalCenter } }
                TextInput {
                    id: query
                    objectName: "query"
                    anchors { left: glass.right; right: parent.right; margins: Theme.space2; verticalCenter: parent.verticalCenter }
                    color: Theme.text
                    font.pixelSize: Theme.fsMd
                    selectByMouse: true
                    Accessible.name: qsTr("Rechercher un logiciel")
                    onTextChanged: { if (text.length > 0) win.page = "search"; searchDelay.restart() }
                    Label { visible: !query.text; text: qsTr("Rechercher parmi les logiciels Debian et Flathub…"); level: Label.Tertiary; anchors.verticalCenter: parent.verticalCenter }
                }
                Timer { id: searchDelay; interval: 400; onTriggered: { DebianPackages.search(query.text, searchTools.checked); Flatpak.search(query.text) } }
            }

            // ---------- À la une ----------
            Column {
                visible: win.page === "home"
                width: parent.width
                spacing: Theme.space5

                // Sélection VinX
                Rectangle {
                    id: hero
                    readonly property var app: win.resolve(Catalog.find(win.pick.pkg))
                    visible: app !== null
                    width: parent.width; height: 132
                    radius: Theme.radiusLg
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#16302A" }
                        GradientStop { position: 1; color: "#1F4B5A" }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (hero.app) win.showApp(hero.app) }
                    AppLogo {
                        id: heroLogo
                        x: Theme.space5; anchors.verticalCenter: parent.verticalCenter
                        size: 84
                        iconUrl: hero.app ? hero.app.iconUrl : ""; themeIcon: hero.app && hero.app.icon ? hero.app.icon : ""
                        name: hero.app ? hero.app.name : ""; tint: hero.app ? hero.app.tint : "#9AA09C"
                    }
                    Column {
                        anchors { left: heroLogo.right; leftMargin: Theme.space5; right: heroButton.left; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                        spacing: 2
                        Label { text: qsTr("SÉLECTION VINX"); color: "#10DD8C"; font.pixelSize: Theme.fsXs; font.weight: Font.DemiBold; font.letterSpacing: 0.8 }
                        Label { text: hero.app ? hero.app.name : ""; color: "#FFFFFF"; font.pixelSize: 24; font.weight: Font.DemiBold }
                        Label { text: win.pick.tagline; color: "#CCFFFFFF"; width: parent.width; wrapMode: Text.WordWrap }
                    }
                    Button {
                        id: heroButton
                        anchors { right: parent.right; rightMargin: Theme.space5; verticalCenter: parent.verticalCenter }
                        text: hero.app && hero.app.installed ? qsTr("Installé") : qsTr("Installer")
                        variant: Button.Primary
                        enabled: hero.app && !hero.app.installed && !DebianPackages.busy && !Flatpak.busy
                        onClicked: hero.app.source === "debian" ? DebianPackages.install(hero.app.package, hero.app.name)
                                                                : Flatpak.install([hero.app.id], hero.app.name)
                    }
                }

                // Rayons en raccourci
                Flow {
                    width: parent.width
                    spacing: Theme.space2
                    Repeater {
                        model: Catalog.categories
                        Rectangle {
                            required property var modelData
                            height: 36; radius: Theme.radiusMd
                            width: chipRow.implicitWidth + Theme.space3 * 2
                            color: chipMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceWindow
                            border.width: 1; border.color: Theme.border
                            Row {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: Theme.space2
                                Rectangle { width: 16; height: 16; radius: 5; color: modelData.tint; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: modelData.name; font.weight: Font.Medium }
                            }
                            MouseArea { id: chipMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.page = "cat:" + modelData.id }
                        }
                    }
                }

                // Populaires, puis un aperçu de chaque rayon
                Repeater {
                    model: [{ title: qsTr("Populaires"), cat: "", entries: Catalog.popular.map(k => Catalog.find(k)) }]
                           .concat(Catalog.categories.map(c => ({ title: c.name, cat: c.id, entries: Catalog.all().filter(a => a.category === c.id) })))
                    Column {
                        id: shelf
                        required property var modelData
                        readonly property var apps: win.resolveAll(modelData.entries).slice(0, content.cols * (modelData.cat ? 1 : 2))
                        visible: apps.length > 0
                        width: parent.width
                        spacing: Theme.space3
                        Item {
                            width: parent.width; height: 26
                            Label { text: shelf.modelData.title; font.pixelSize: Theme.fsLg; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                            Label {
                                visible: shelf.modelData.cat !== ""
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                text: qsTr("Tout voir"); color: Theme.accentForeground; font.weight: Font.Medium
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.page = "cat:" + shelf.modelData.cat }
                            }
                        }
                        Flow {
                            width: parent.width
                            spacing: Theme.space3
                            Repeater {
                                model: shelf.apps
                                AppCard { required property var modelData; app: modelData; width: content.cardWidth; onOpenDetails: win.showApp(modelData) }
                            }
                        }
                    }
                }
                Label {
                    visible: DebianPackages.catalogLoading
                    text: qsTr("Chargement du catalogue…"); level: Label.Tertiary
                }
            }

            // ---------- Rayon ----------
            Column {
                readonly property var cat: win.page.startsWith("cat:") ? Catalog.category(win.page.slice(4)) : null
                visible: cat !== null
                width: parent.width
                spacing: Theme.space4
                Row {
                    spacing: Theme.space3
                    Rectangle { width: 22; height: 22; radius: 7; color: parent.parent.cat ? parent.parent.cat.tint : "transparent"; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: parent.parent.cat ? parent.parent.cat.name : ""; font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold }
                }
                Flow {
                    width: parent.width
                    spacing: Theme.space3
                    Repeater {
                        model: parent.parent.cat ? win.resolveAll(parent.parent.cat.apps.map(a => Object.assign({ tint: parent.parent.cat.tint }, a))) : []
                        AppCard { required property var modelData; app: modelData; width: content.cardWidth; onOpenDetails: win.showApp(modelData) }
                    }
                }
            }

            // ---------- Recherche : Debian et Flathub mélangés ----------
            Column {
                visible: win.page === "search"
                width: parent.width
                spacing: Theme.space4
                // Debian d'abord ; une application Flathub déjà proposée par Debian (même nom) est masquée.
                readonly property var results: {
                    Flatpak.iconsRevision   // logos disponibles après le téléchargement du catalogue
                    const deb = DebianPackages.results.map(r => ({ source: "debian", name: r.name, summary: r.summary, package: r.package, id: r.id,
                                                                    iconUrl: r.iconUrl || "", icon: r.icon || "", installed: r.installed === true }))
                    const names = deb.map(d => d.name.toLowerCase())
                    const fp = Flatpak.searchResults.filter(r => names.indexOf((r.name || "").toLowerCase()) < 0)
                        .map(r => ({ source: "flathub", name: r.name, summary: r.summary, id: r.id, iconUrl: Flatpak.iconUrl(r.id),
                                     installed: Flatpak.installed.indexOf(r.id) >= 0 }))
                    return deb.concat(fp)
                }
                Row {
                    spacing: Theme.space2
                    Switch { id: searchTools; onToggled: DebianPackages.search(query.text, checked) }
                    Label { text: qsTr("Inclure les outils techniques (sans interface graphique)"); level: Label.Secondary; anchors.verticalCenter: parent.verticalCenter }
                }
                Label {
                    readonly property bool busy: DebianPackages.searching || Flatpak.searching
                    visible: busy || (query.text.length >= 2 && parent.results.length === 0) || query.text.length < 2
                    text: query.text.length < 2 ? qsTr("Tapez le nom d'un logiciel ou ce que vous voulez faire (« photo », « musique »…).")
                        : busy ? qsTr("Recherche…") : qsTr("Aucun résultat.")
                    level: Label.Secondary
                }
                Flow {
                    width: parent.width
                    spacing: Theme.space3
                    Repeater {
                        model: parent.parent.results
                        AppCard { required property var modelData; app: modelData; width: content.cardWidth; onOpenDetails: win.showApp(modelData) }
                    }
                }
            }

            // ---------- Installées ----------
            Column {
                visible: win.page === "installed"
                width: parent.width
                spacing: Theme.space4
                readonly property var apps: {
                    Flatpak.iconsRevision
                    const deb = win.resolveAll(Catalog.all()).filter(a => a.source === "debian" && a.installed)
                    const fp = Flatpak.installedApps.map(a => ({ source: "flathub", name: a.name || a.id, summary: a.version ? qsTr("Version %1").arg(a.version) : a.id,
                                                                 id: a.id, iconUrl: Flatpak.iconUrl(a.id), installed: true }))
                    return deb.concat(fp)
                }
                Label { text: qsTr("Installées"); font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold }
                Flow {
                    width: parent.width
                    spacing: Theme.space3
                    Repeater {
                        model: parent.parent.apps
                        AppCard { required property var modelData; app: modelData; width: content.cardWidth; onOpenDetails: win.showApp(modelData) }
                    }
                }
                Label { visible: parent.apps.length === 0; text: qsTr("Aucun logiciel du Store installé pour l'instant."); level: Label.Secondary }
            }
        }
    }

    AppDetail { id: detail }
}
