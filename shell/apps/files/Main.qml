import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell
import Vinx.Files

// Fichiers : gestionnaire de fichiers minimal de VinX OS.
// Interface VinX ; copies, corbeille, réseau et conflits délégués à KIO (KDE).
Window {
    id: win
    width: 1040; height: 680
    minimumWidth: 640; minimumHeight: 420
    visible: true
    title: folder.title
    color: Theme.surfaceWindow
    AppearanceSync {}

    property url startUrl
    readonly property int rev: Preferences.revision
    readonly property bool listView: (rev, Preferences.value("files/view", "grid") === "list")

    // ---------- État ----------
    FolderModel {
        id: folder
        url: win.startUrl
        showHidden: (win.rev, String(Preferences.value("files/showHidden", false)) === "true")
        onUrlChanged: { win.clearSelection(); filterField.text = "" }
        onCountChanged: if (win.current >= count) win.current = count - 1
    }
    // Onglets : [{ url, back, forward }] ; la barre n'apparaît qu'à partir de deux onglets.
    property var tabs: [{ url: win.startUrl, back: [], forward: [] }]
    property int tab: 0
    function saveTab() { const t = tabs.slice(); t[tab] = { url: folder.url, back: back, forward: forward }; tabs = t }
    function switchTab(i) {
        if (i < 0 || i >= tabs.length || i === tab) return
        saveTab(); tab = i
        back = tabs[i].back; forward = tabs[i].forward; folder.url = tabs[i].url
    }
    function newTab(url) { saveTab(); tabs = tabs.concat([{ url: url || folder.url, back: [], forward: [] }]); switchTab(tabs.length - 1) }
    function closeTab(i) {
        if (tabs.length <= 1) { Qt.quit(); return }
        saveTab()
        const t = tabs.slice(); t.splice(i, 1)
        const next = Math.min(i <= tab ? Math.max(0, tab - 1) : tab, t.length - 1)
        tabs = t; tab = -1; tab = next
        back = tabs[next].back; forward = tabs[next].forward; folder.url = tabs[next].url
    }
    function tabTitle(t, i) { return i === tab ? folder.title : decodeURIComponent(t.url.toString().replace(/\/$/, "").split("/").pop()) || "/" }
    property var back: []
    property var forward: []
    property var selected: ({})          // nom → true
    property int current: -1             // élément ayant le focus clavier
    property int anchor: -1              // début d'une sélection avec Maj
    property string renaming: ""         // nom en cours de renommage
    property string pendingSelect: ""    // élément à sélectionner quand il apparaîtra

    function go(url, keepForward) {
        if (!url || url.toString() === folder.url.toString()) return
        back = back.concat([folder.url]); if (!keepForward) forward = []
        folder.url = url
    }
    function goBack() { if (!back.length) return; forward = [folder.url].concat(forward); const u = back[back.length - 1]; back = back.slice(0, -1); folder.url = u }
    function goForward() { if (!forward.length) return; back = back.concat([folder.url]); const u = forward[0]; forward = forward.slice(1); folder.url = u }
    function goUp() { if (folder.canGoUp) { const name = folder.url.toString().split("/").pop(); go(folder.parentUrl()); pendingSelect = decodeURIComponent(name) } }

    function clearSelection() { selected = ({}); current = -1; anchor = -1; renaming = "" }
    function isSelected(name) { return selected[name] === true }
    function selectedUrls() {
        const out = []
        for (let i = 0; i < folder.count; ++i) { const e = folder.get(i); if (selected[e.name]) out.push(e.url) }
        if (!out.length && current >= 0) out.push(folder.get(current).url)
        return out
    }
    readonly property int selectedCount: Object.keys(selected).length
    function select(index, modifiers) {
        if (index < 0 || index >= folder.count) return
        const name = folder.get(index).name
        let s = Object.assign({}, selected)
        if (modifiers & Qt.ShiftModifier && anchor >= 0) {
            if (!(modifiers & Qt.ControlModifier)) s = {}
            for (let i = Math.min(anchor, index); i <= Math.max(anchor, index); ++i) s[folder.get(i).name] = true
        } else if (modifiers & Qt.ControlModifier) {
            if (s[name]) delete s[name]; else s[name] = true
            anchor = index
        } else {
            s = {}; s[name] = true; anchor = index
        }
        selected = s; current = index; renaming = ""
    }
    function selectAll() { const s = {}; for (let i = 0; i < folder.count; ++i) s[folder.get(i).name] = true; selected = s }
    function activate(index) {
        const e = folder.get(index)
        if (!e.name) return
        if (e.isDir) go(e.url); else FileOps.open(e.url)
    }
    function paste() { if (FileOps.canPaste) conflict.ask(FileOps.clipboardUrls(), folder.url, FileOps.clipboardIsCut()) }
    // Glisser-déposer : déplacement par défaut (même disque local), copie avec Ctrl ou vers ailleurs.
    // Dépôt : on ignore les éléments déjà dans le dossier de destination (lâcher un fichier là où il
    // est créait une copie « nom (1) ») et un dossier déposé dans lui-même ou un de ses sous-dossiers.
    function parentOf(u) { const s = u.toString().replace(/\/+$/, ""); return s.slice(0, s.lastIndexOf("/")) }
    function dropUrls(urls, dest, copyRequested) {
        const d = dest.toString().replace(/\/+$/, "")
        const list = urls.filter(u => {
            const s = u.toString().replace(/\/+$/, "")
            return s !== d && parentOf(s) !== d && !d.startsWith(s + "/")
        })
        if (!list.length || win.inTrash) return
        const sameLocal = dest.toString().startsWith("file:") && list.every(u => u.toString().startsWith("file:"))
        conflict.ask(list, dest, sameLocal && !copyRequested)
    }
    function startRename() { if (current >= 0 && !inTrash) renaming = folder.get(current).name }
    function newFolder() { pendingSelect = FileOps.createFolder(folder.url, qsTr("Nouveau dossier")); pendingRename = true }
    property bool pendingRename: false
    readonly property bool inTrash: folder.url.toString().startsWith("trash:")

    Connections {
        target: folder
        function onCountChanged() {
            if (!win.pendingSelect) return
            const i = folder.indexOfName(win.pendingSelect)
            if (i < 0) return
            win.select(i, 0); win.pendingSelect = ""
            if (win.pendingRename) { win.pendingRename = false; win.startRename() }
            view.item.positionAt(i)
        }
    }
    Connections { target: FileOps; function onFailed(message) { banner.show(message) } }

    // ---------- Raccourcis ----------
    Shortcut { sequences: [StandardKey.Back, "Alt+Left", "Backspace"]; enabled: !win.renaming && !filterField.activeFocus && !pathBar.editing; onActivated: win.goBack() }
    Shortcut { sequences: [StandardKey.Forward, "Alt+Right"]; onActivated: win.goForward() }
    Shortcut { sequence: "Alt+Up"; onActivated: win.goUp() }
    Shortcut { sequence: "Alt+Home"; onActivated: win.go(folder.urlFromText("~")) }
    Shortcut { sequence: "Ctrl+L"; onActivated: pathBar.edit() }
    Shortcut { sequences: [StandardKey.Find]; onActivated: filterField.forceActiveFocus() }
    Shortcut { sequence: "Ctrl+H"; onActivated: Preferences.setValue("files/showHidden", !folder.showHidden) }
    Shortcut { sequence: "Ctrl+Shift+N"; enabled: !win.inTrash; onActivated: win.newFolder() }
    Shortcut { sequence: "F5"; onActivated: folder.refresh() }
    Shortcut { sequences: [StandardKey.AddTab]; onActivated: win.newTab() }
    Shortcut { sequences: [StandardKey.Close]; onActivated: win.closeTab(win.tab) }
    Shortcut { sequence: "Ctrl+Tab"; onActivated: win.switchTab((win.tab + 1) % win.tabs.length) }
    Shortcut { sequence: "Ctrl+Shift+Tab"; onActivated: win.switchTab((win.tab + win.tabs.length - 1) % win.tabs.length) }
    Shortcut { sequence: "F2"; onActivated: win.startRename() }
    Shortcut { sequences: [StandardKey.SelectAll]; enabled: !win.renaming && !filterField.activeFocus; onActivated: win.selectAll() }
    Shortcut { sequences: [StandardKey.Copy]; enabled: !win.renaming && !filterField.activeFocus; onActivated: FileOps.setClipboard(win.selectedUrls(), false) }
    Shortcut { sequences: [StandardKey.Cut]; enabled: !win.renaming && !filterField.activeFocus && !win.inTrash; onActivated: FileOps.setClipboard(win.selectedUrls(), true) }
    Shortcut { sequences: [StandardKey.Paste]; enabled: !win.renaming && !filterField.activeFocus && !win.inTrash; onActivated: win.paste() }
    Shortcut { sequences: [StandardKey.Delete]; enabled: !win.renaming && !filterField.activeFocus && !win.inTrash; onActivated: FileOps.trash(win.selectedUrls()) }
    Shortcut { sequence: "Ctrl+1"; onActivated: Preferences.setValue("files/view", "grid") }
    Shortcut { sequence: "Ctrl+2"; onActivated: Preferences.setValue("files/view", "list") }

    // ---------- Barre latérale ----------
    Sidebar {
        id: sidebar
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        currentUrl: folder.url
        source: folder
        onOpenRequested: (url) => win.go(url)
        // Corbeille : y déposer = mettre à la corbeille.
        onDropRequested: (urls, dest, copy) => dest.toString().startsWith("trash:") ? FileOps.trash(urls) : win.dropUrls(urls, dest, copy)
    }

    // ---------- Barre d'outils ----------
    Item {
        id: toolbar
        anchors { left: sidebar.right; right: parent.right; top: parent.top }
        height: 52
        Row {
            id: nav
            anchors { left: parent.left; leftMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            spacing: 2
            IconButton { flat: true; iconName: "chevron-l"; toolTip: qsTr("Précédent (Alt+←)"); enabled: win.back.length > 0; onClicked: win.goBack() }
            IconButton { flat: true; iconName: "chevron-r"; toolTip: qsTr("Suivant (Alt+→)"); enabled: win.forward.length > 0; onClicked: win.goForward() }
        }
        PathBar {
            id: pathBar
            anchors { left: nav.right; leftMargin: Theme.space2; right: tools.left; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            model: folder
            onOpenRequested: (url) => win.go(url)
        }
        Row {
            id: tools
            anchors { right: parent.right; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            spacing: Theme.space2
            Rectangle {
                width: 200; height: 30; radius: Theme.radiusSm
                color: Theme.surfaceSunken
                border.width: filterField.activeFocus ? 2 : 1
                border.color: filterField.activeFocus ? Theme.accentForeground : Theme.border
                anchors.verticalCenter: parent.verticalCenter
                Icon { id: glass; name: "search"; width: 14; height: 14; color: Theme.textTertiary; anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter } }
                TextInput {
                    id: filterField
                    anchors { left: glass.right; right: parent.right; margins: Theme.space2; verticalCenter: parent.verticalCenter }
                    color: Theme.text; font.pixelSize: Theme.fsMd; clip: true
                    selectByMouse: true
                    Accessible.name: qsTr("Filtrer ce dossier")
                    onTextChanged: folder.filter = text
                    Keys.onEscapePressed: { text = ""; view.forceActiveFocus() }
                    Keys.onDownPressed: { view.forceActiveFocus(); if (folder.count) win.select(0, 0) }
                    Label { visible: !filterField.text; text: qsTr("Filtrer"); level: Label.Tertiary; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            SegmentedControl {
                anchors.verticalCenter: parent.verticalCenter
                model: [qsTr("Icônes"), qsTr("Liste")]
                currentIndex: win.listView ? 1 : 0
                onActivated: (i) => Preferences.setValue("files/view", i === 1 ? "list" : "grid")
            }
            IconButton { flat: true; iconName: "folder-plus"; toolTip: qsTr("Nouveau dossier (Ctrl+Maj+N)"); enabled: !win.inTrash; onClicked: win.newFolder(); anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Theme.border }
    }

    // ---------- Onglets ----------
    Row {
        id: tabBar
        visible: win.tabs.length > 1
        anchors { left: sidebar.right; right: parent.right; top: toolbar.bottom; leftMargin: Theme.space3; rightMargin: Theme.space3 }
        height: visible ? 36 : 0
        spacing: Theme.space1
        Repeater {
            model: win.tabs
            delegate: Rectangle {
                id: tabItem
                required property var modelData
                required property int index
                readonly property bool current: index === win.tab
                width: Math.min(200, (tabBar.width - (win.tabs.length - 1) * tabBar.spacing) / win.tabs.length)
                height: 28; y: 4
                radius: Theme.radiusSm
                color: current ? Theme.surfaceActive : tabMouse.containsMouse ? Theme.surfaceHover : "transparent"
                Label {
                    anchors { left: parent.left; right: closeTab.left; leftMargin: Theme.space3; verticalCenter: parent.verticalCenter }
                    text: win.tabTitle(tabItem.modelData, tabItem.index)
                    font.weight: tabItem.current ? Font.DemiBold : Font.Normal; font.pixelSize: Theme.fsSm
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: tabMouse; anchors.fill: parent; hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: (m) => m.button === Qt.MiddleButton ? win.closeTab(tabItem.index) : win.switchTab(tabItem.index)
                }
                IconButton {
                    id: closeTab
                    flat: true; width: 20; height: 20
                    iconName: "close"; toolTip: qsTr("Fermer l'onglet (Ctrl+W)")
                    anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                    onClicked: win.closeTab(tabItem.index)
                }
            }
        }
    }

    // ---------- Contenu ----------
    Item {
        id: content
        anchors { left: sidebar.right; right: parent.right; top: tabBar.bottom; bottom: status.top }

        Rectangle {
            id: trashBar
            visible: win.inTrash
            width: parent.width; height: visible ? 44 : 0
            color: Theme.surfaceSunken
            Label { text: qsTr("Les éléments de la corbeille peuvent être restaurés depuis leur menu."); level: Label.Secondary; anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter } }
            Button { text: qsTr("Vider la corbeille"); variant: Button.Secondary; enabled: folder.count > 0; anchors { right: parent.right; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter } onClicked: FileOps.emptyTrash() }
        }

        Loader {
            id: view
            anchors { left: parent.left; right: parent.right; top: trashBar.bottom; bottom: parent.bottom }
            focus: true
            sourceComponent: win.listView ? listComp : gridComp
            Keys.onPressed: (e) => {
                const cols = item && item.columns ? item.columns : 1
                let target = -1
                if (e.key === Qt.Key_Right && !win.listView) target = win.current + 1
                else if (e.key === Qt.Key_Left && !win.listView) target = win.current - 1
                else if (e.key === Qt.Key_Down) target = win.current < 0 ? 0 : win.current + cols
                else if (e.key === Qt.Key_Up) target = win.current - cols
                else if (e.key === Qt.Key_Home) target = 0
                else if (e.key === Qt.Key_End) target = folder.count - 1
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (win.current >= 0) win.activate(win.current); e.accepted = true; return }
                else if (e.key === Qt.Key_Escape) { win.clearSelection(); e.accepted = true; return }
                else if (e.text.length === 1 && e.text.trim() && !(e.modifiers & Qt.ControlModifier)) {
                    // Saisie au clavier : aller au premier élément commençant par cette lettre.
                    for (let i = 0; i < folder.count; ++i) {
                        const k = (win.current + 1 + i) % folder.count
                        if (folder.get(k).name.toLowerCase().startsWith(e.text.toLowerCase())) { target = k; break }
                    }
                } else return
                e.accepted = true
                if (target >= 0 && target < folder.count) { win.select(target, e.modifiers); item.positionAt(target) }
            }
        }
        // Dépôt dans le dossier courant (depuis Fichiers ou une autre application).
        DropArea {
            anchors.fill: view
            keys: ["text/uri-list"]
            onDropped: (drop) => { win.dropUrls(drop.urls, folder.url, drop.proposedAction === Qt.CopyAction || (drop.modifiers & Qt.ControlModifier)); drop.accept() }
        }
        Component { id: gridComp; FileGrid { model: folder; host: win; onContextMenu: (i, x, y) => win.showMenu(i, x, y, this) } }
        Component { id: listComp; FileList { model: folder; host: win; onContextMenu: (i, x, y) => win.showMenu(i, x, y, this) } }

        Column {
            anchors.centerIn: parent
            spacing: Theme.space2
            visible: folder.count === 0 && !folder.loading
            Icon { name: folder.error ? "info" : win.inTrash ? "trash" : "folder"; width: 40; height: 40; color: Theme.textTertiary; anchors.horizontalCenter: parent.horizontalCenter }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: folder.error ? folder.error : folder.filter ? qsTr("Aucun élément ne correspond à « %1 ».").arg(folder.filter)
                    : win.inTrash ? qsTr("La corbeille est vide.") : qsTr("Ce dossier est vide.")
                level: Label.Secondary
            }
        }

        // Bandeau d'erreur
        Rectangle {
            id: banner
            function show(msg) { bannerText.text = msg; visible = true; bannerTimer.restart() }
            visible: false
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.space3 }
            height: 40; radius: Theme.radiusMd
            color: Theme.surfaceGlassStrong
            border.width: 1; border.color: Theme.danger
            Label { id: bannerText; anchors { left: parent.left; leftMargin: Theme.space3; right: closeBanner.left; verticalCenter: parent.verticalCenter } elide: Text.ElideRight }
            IconButton { id: closeBanner; flat: true; iconName: "close"; anchors { right: parent.right; rightMargin: Theme.space1; verticalCenter: parent.verticalCenter } onClicked: banner.visible = false }
            Timer { id: bannerTimer; interval: 8000; onTriggered: banner.visible = false }
        }
    }

    // ---------- Barre d'état ----------
    Item {
        id: status
        anchors { left: sidebar.right; right: parent.right; bottom: parent.bottom }
        height: 30
        Rectangle { width: parent.width; height: 1; color: Theme.border }
        Label {
            anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
            level: Label.Secondary; font.pixelSize: Theme.fsSm
            text: {
                const n = qsTr("%n élément(s)", "", folder.count)
                if (win.selectedCount === 1 && win.current >= 0) { const e = folder.get(win.current); return n + " · « " + e.name + " »" + (e.sizeText ? " · " + e.sizeText : "") }
                return win.selectedCount > 1 ? n + " · " + qsTr("%n sélectionné(s)", "", win.selectedCount) : n
            }
        }
        Row {
            visible: FileOps.busy
            anchors { right: parent.right; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
            spacing: Theme.space2
            Label { text: FileOps.task; level: Label.Secondary; font.pixelSize: Theme.fsSm; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                visible: FileOps.progress >= 0
                width: 100; height: 4; radius: 2; color: Theme.surfaceActive; anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: parent.width * Math.max(0.04, FileOps.progress / 100); height: parent.height; radius: 2; color: Theme.accent }
            }
        }
    }

    // ---------- Menu contextuel ----------
    function showMenu(index, x, y, source) {
        if (index >= 0 && !isSelected(folder.get(index).name)) select(index, 0)
        if (index < 0) clearSelection()
        const p = source.mapToItem(menuLayer, x, y)
        contextMenu.target = index
        contextMenu.anchorItem = null
        contextMenu.anchorRect = Qt.rect(p.x, p.y, 1, 1)
        contextMenu.show()
    }
    Item {
        id: menuLayer
        anchors.fill: parent
        z: 100
        Menu {
            id: contextMenu
            property int target: -1
            readonly property bool onItem: target >= 0
            readonly property var entries: win.inTrash
                ? (onItem ? [{ text: qsTr("Restaurer"), act: "restore" }, { separator: true }, { text: qsTr("Supprimer définitivement"), act: "delete" }]
                          : [{ text: qsTr("Vider la corbeille"), act: "empty", enabled: folder.count > 0 }])
                : onItem
                ? [{ text: qsTr("Ouvrir"), act: "open", shortcut: qsTr("Entrée") }].concat(
                   win.current >= 0 && folder.get(win.current).isDir ? [{ text: qsTr("Ouvrir dans un nouvel onglet"), act: "tab" }] : []).concat([
                   { separator: true },
                   { text: qsTr("Couper"), act: "cut", shortcut: "Ctrl+X" },
                   { text: qsTr("Copier"), act: "copy", shortcut: "Ctrl+C" },
                   { text: qsTr("Coller"), act: "paste", shortcut: "Ctrl+V", enabled: FileOps.canPaste },
                   { separator: true },
                   { text: qsTr("Renommer…"), act: "rename", shortcut: "F2", enabled: win.selectedCount <= 1 },
                   { text: qsTr("Mettre à la corbeille"), act: "trash", shortcut: qsTr("Suppr") }])
                : [{ text: qsTr("Nouveau dossier"), act: "mkdir", shortcut: "Ctrl+Maj+N" },
                   { text: qsTr("Coller"), act: "paste", shortcut: "Ctrl+V", enabled: FileOps.canPaste },
                   { separator: true },
                   { text: qsTr("Afficher les fichiers cachés"), act: "hidden", checked: folder.showHidden, shortcut: "Ctrl+H" },
                   { text: qsTr("Ouvrir un terminal ici"), act: "terminal" }]
            model: entries
            onTriggered: (i, e) => {
                switch (e.act) {
                case "open": win.activate(win.current); break
                case "tab": win.newTab(folder.get(win.current).url); break
                case "cut": FileOps.setClipboard(win.selectedUrls(), true); break
                case "copy": FileOps.setClipboard(win.selectedUrls(), false); break
                case "paste": win.paste(); break
                case "rename": win.startRename(); break
                case "trash": FileOps.trash(win.selectedUrls()); break
                case "mkdir": win.newFolder(); break
                case "hidden": Preferences.setValue("files/showHidden", !folder.showHidden); break
                case "terminal": FileOps.openTerminal(folder.url); break
                case "empty": FileOps.emptyTrash(); break
                case "restore": FileOps.restore(win.selectedUrls()); break
                case "delete": FileOps.deletePermanently(win.selectedUrls()); break
                }
                view.forceActiveFocus()
            }
        }
    }

    ConflictDialog { id: conflict }

    Component.onCompleted: view.forceActiveFocus()
}
