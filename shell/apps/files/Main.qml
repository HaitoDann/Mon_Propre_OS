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
    Shortcut { sequence: "F2"; onActivated: win.startRename() }
    Shortcut { sequences: [StandardKey.SelectAll]; enabled: !win.renaming && !filterField.activeFocus; onActivated: win.selectAll() }
    Shortcut { sequences: [StandardKey.Copy]; enabled: !win.renaming && !filterField.activeFocus; onActivated: FileOps.setClipboard(win.selectedUrls(), false) }
    Shortcut { sequences: [StandardKey.Cut]; enabled: !win.renaming && !filterField.activeFocus && !win.inTrash; onActivated: FileOps.setClipboard(win.selectedUrls(), true) }
    Shortcut { sequences: [StandardKey.Paste]; enabled: !win.renaming && !filterField.activeFocus && !win.inTrash; onActivated: FileOps.paste(folder.url) }
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

    // ---------- Contenu ----------
    Item {
        id: content
        anchors { left: sidebar.right; right: parent.right; top: toolbar.bottom; bottom: status.top }

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
                ? [{ text: qsTr("Ouvrir"), act: "open", shortcut: qsTr("Entrée") },
                   { separator: true },
                   { text: qsTr("Couper"), act: "cut", shortcut: "Ctrl+X" },
                   { text: qsTr("Copier"), act: "copy", shortcut: "Ctrl+C" },
                   { text: qsTr("Coller"), act: "paste", shortcut: "Ctrl+V", enabled: FileOps.canPaste },
                   { separator: true },
                   { text: qsTr("Renommer…"), act: "rename", shortcut: "F2", enabled: win.selectedCount <= 1 },
                   { text: qsTr("Mettre à la corbeille"), act: "trash", shortcut: qsTr("Suppr") }]
                : [{ text: qsTr("Nouveau dossier"), act: "mkdir", shortcut: "Ctrl+Maj+N" },
                   { text: qsTr("Coller"), act: "paste", shortcut: "Ctrl+V", enabled: FileOps.canPaste },
                   { separator: true },
                   { text: qsTr("Afficher les fichiers cachés"), act: "hidden", checked: folder.showHidden, shortcut: "Ctrl+H" },
                   { text: qsTr("Ouvrir un terminal ici"), act: "terminal" }]
            model: entries
            onTriggered: (i, e) => {
                switch (e.act) {
                case "open": win.activate(win.current); break
                case "cut": FileOps.setClipboard(win.selectedUrls(), true); break
                case "copy": FileOps.setClipboard(win.selectedUrls(), false); break
                case "paste": FileOps.paste(folder.url); break
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

    Component.onCompleted: view.forceActiveFocus()
}
