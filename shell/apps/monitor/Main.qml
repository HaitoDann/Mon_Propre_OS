import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import Vinx.Shell
import Vinx.Monitor

// Moniteur système (ADR 0035) : bandeau de mini-graphiques (processeur, mémoire, disque, réseau)
// et une seule liste par application, dépliable en processus. Les valeurs fortes se colorent.
Window {
    id: win
    width: 900; height: 620
    minimumWidth: 640; minimumHeight: 420
    visible: true
    title: qsTr("Moniteur système")
    color: Theme.surfaceWindow
    AppearanceSync {}

    property string startQuery: ""
    property string selectedKey: ""
    property string closingKey: ""       // application fermée qui ne répond pas encore
    property string closingName: ""
    readonly property int selectedRow: { procs.count; procs.processCount; return procs.indexOf(selectedKey) }
    readonly property bool selectionOwn: { procs.processCount; return selectedRow >= 0 && procs.canAct(selectedKey) }

    ProcessModel {
        id: procs
        property int count: 0
        onRowsInserted: count++
        onRowsRemoved: count++
        onRowsMoved: count++
        Component.onCompleted: if (win.startQuery) filter = win.startQuery
    }

    // ---------- Mise en forme ----------
    function num(v, d) { return Number(v).toLocaleString(Qt.locale(), "f", d) }
    function bytes(v) {
        if (v >= 1073741824) return qsTr("%1 Go").arg(num(v / 1073741824, 1))
        if (v >= 1048576) return qsTr("%1 Mo").arg(num(v / 1048576, 0))
        return qsTr("%1 ko").arg(num(Math.max(0, v) / 1024, 0))
    }
    function rate(v) { return v < 1024 ? "—" : qsTr("%1/s").arg(bytes(v)) }
    function percent(v) { return qsTr("%1 %").arg(num(v, v < 10 && v > 0 ? 1 : 0)) }
    // 0 normal, 1 notable, 2 fort : coloration des cases.
    function heat(column, v) {
        if (column === ProcessModel.Cpu) return v >= 25 ? 2 : v >= 8 ? 1 : 0
        if (column === ProcessModel.Memory) { const r = procs.memTotal > 0 ? v / procs.memTotal : 0; return r >= 0.2 ? 2 : r >= 0.08 ? 1 : 0 }
        return v >= 20971520 ? 2 : v >= 2097152 ? 1 : 0
    }

    // ---------- Actions ----------
    function closeSelected(force) {
        if (!selectedKey) return
        const name = procs.name(selectedKey)
        if (force) { procs.forceClose(selectedKey); closingKey = ""; return }
        if (procs.close(selectedKey)) { closingKey = selectedKey; closingName = name; closeCheck.restart() }
    }
    Timer {
        id: closeCheck
        interval: 4000
        onTriggered: if (!procs.isRunning(win.closingKey)) win.closingKey = ""
    }
    function select(row) {
        if (row < 0 || row >= list.count) return
        list.currentIndex = row
        const it = list.itemAtIndex(row)
        if (it) selectedKey = it.key
    }

    Shortcut { sequences: [StandardKey.Find]; onActivated: search.forceActiveFocus() }
    Shortcut { sequence: "Delete"; enabled: !search.activeFocus; onActivated: win.closeSelected(false) }
    Shortcut { sequence: "Shift+Delete"; enabled: !search.activeFocus; onActivated: win.closeSelected(true) }
    Shortcut { sequence: "Escape"; onActivated: search.text ? search.text = "" : (menu.open ? menu.close() : win.close()) }

    // ---------- Barre du haut : recherche ----------
    Item {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 52
        Rectangle {
            id: searchBox
            anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
            width: Math.min(320, parent.width * 0.45); height: 32
            radius: Theme.radiusSm
            color: Theme.surfaceSunken
            border.width: search.activeFocus ? 2 : 1
            border.color: search.activeFocus ? Theme.accent : Theme.border
            Icon { id: glass; name: "search"; width: 14; height: 14; color: Theme.textTertiary; anchors { left: parent.left; leftMargin: Theme.space2; verticalCenter: parent.verticalCenter } }
            TextInput {
                id: search
                objectName: "search"
                anchors { left: glass.right; right: parent.right; margins: Theme.space2; verticalCenter: parent.verticalCenter }
                color: Theme.text
                font.pixelSize: Theme.fsMd
                selectByMouse: true
                clip: true
                text: win.startQuery
                Accessible.name: qsTr("Rechercher une application ou un processus")
                onTextChanged: filterDelay.restart()
                Keys.onDownPressed: { list.forceActiveFocus(); win.select(0) }
                Label { visible: !search.text; text: qsTr("Rechercher (nom, numéro)…"); level: Label.Tertiary; anchors.verticalCenter: parent.verticalCenter }
            }
            Timer { id: filterDelay; interval: 200; onTriggered: procs.filter = search.text }
        }
        Label {
            anchors { right: parent.right; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
            level: Label.Tertiary
            font.pixelSize: Theme.fsSm
            text: qsTr("%1 processus").arg(procs.processCount)
        }
    }

    // ---------- Bandeau des mini-graphiques ----------
    Row {
        id: strip
        anchors { left: parent.left; right: parent.right; top: header.bottom }
        height: 78
        readonly property real cell: width / 4
        Repeater {
            model: [
                { title: qsTr("Processeur"), value: win.percent(procs.cpu), history: procs.cpuHistory, max: 100, color: Theme.accent, sort: ProcessModel.Cpu },
                { title: qsTr("Mémoire"), value: qsTr("%1 / %2").arg(win.bytes(procs.memUsed)).arg(win.bytes(procs.memTotal)), history: procs.memHistory, max: 100, color: "#2E9BFF", sort: ProcessModel.Memory },
                { title: qsTr("Disque · lecture / écriture"), value: qsTr("%1 / %2").arg(win.rate(procs.diskRead)).arg(win.rate(procs.diskWrite)), history: procs.diskHistory, max: 0, color: "#B06AE0", sort: ProcessModel.Disk },
                { title: qsTr("Réseau · ↓ / ↑"), value: qsTr("%1 / %2").arg(win.rate(procs.netIn)).arg(win.rate(procs.netOut)), history: procs.netHistory, max: 0, color: "#D4A13C", sort: -1 }
            ]
            Rectangle {
                id: cellItem
                required property var modelData
                required property int index
                width: strip.cell; height: strip.height
                readonly property bool active: modelData.sort === procs.sortColumn
                color: cellMouse.containsMouse && modelData.sort >= 0 ? Theme.surfaceHover : "transparent"
                Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.border; visible: cellItem.index < 3 }
                Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 2; color: cellItem.modelData.color; visible: cellItem.active }
                Column {
                    anchors { fill: parent; margins: Theme.space3; bottomMargin: Theme.space2 }
                    spacing: 1
                    Label { text: cellItem.modelData.title; level: Label.Tertiary; font.pixelSize: Theme.fsSm; width: parent.width; elide: Text.ElideRight }
                    Label { text: cellItem.modelData.value; font.weight: Font.DemiBold; font.pixelSize: Theme.fsMd; width: parent.width; elide: Text.ElideRight }
                    Sparkline { width: parent.width; height: 24; values: cellItem.modelData.history; maximum: cellItem.modelData.max; color: cellItem.modelData.color }
                }
                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: cellItem.modelData.sort >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: if (cellItem.modelData.sort >= 0) procs.sortColumn = cellItem.modelData.sort
                }
                Accessible.role: Accessible.Button
                Accessible.name: modelData.title + " " + modelData.value
            }
        }
    }
    Rectangle { anchors { left: parent.left; right: parent.right; top: strip.bottom } height: 1; color: Theme.border }

    // ---------- En-têtes de colonnes ----------
    readonly property real colWidth: Math.max(96, Math.min(130, width * 0.13))
    Item {
        id: columns
        anchors { left: parent.left; right: parent.right; top: strip.bottom; topMargin: 1 }
        height: 34
        Row {
            anchors { fill: parent; leftMargin: Theme.space4; rightMargin: Theme.space4 }
            Repeater {
                model: [
                    { title: qsTr("Application"), sort: ProcessModel.Name },
                    { title: qsTr("Processeur"), sort: ProcessModel.Cpu },
                    { title: qsTr("Mémoire"), sort: ProcessModel.Memory },
                    { title: qsTr("Disque"), sort: ProcessModel.Disk }
                ]
                Item {
                    id: colHead
                    required property var modelData
                    required property int index
                    width: index === 0 ? columns.width - Theme.space4 * 2 - win.colWidth * 3 : win.colWidth
                    height: columns.height
                    readonly property bool active: procs.sortColumn === modelData.sort
                    Label {
                        anchors { verticalCenter: parent.verticalCenter; left: colHead.index === 0 ? parent.left : undefined; right: colHead.index === 0 ? undefined : parent.right; rightMargin: Theme.space2 }
                        text: colHead.modelData.title.toUpperCase() + (colHead.active ? (colHead.index === 0 ? "  ▴" : "  ▾") : "")
                        font.pixelSize: Theme.fsXs
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.4
                        color: colHead.active ? Theme.text : Theme.textTertiary
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: procs.sortColumn = colHead.modelData.sort }
                    Accessible.role: Accessible.ColumnHeader
                    Accessible.name: modelData.title
                }
            }
        }
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Theme.border }
    }

    // ---------- Liste ----------
    ListView {
        id: list
        objectName: "processList"
        anchors { left: parent.left; right: parent.right; top: columns.bottom; bottom: notice.visible ? notice.top : footer.top }
        clip: true
        model: procs
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: true
        activeFocusOnTab: true
        highlightFollowsCurrentItem: false
        currentIndex: win.selectedRow
        Keys.onUpPressed: win.select(Math.max(0, win.selectedRow - 1))
        Keys.onDownPressed: win.select(Math.min(count - 1, win.selectedRow + 1))
        Keys.onRightPressed: procs.setExpanded(win.selectedKey, true)
        Keys.onLeftPressed: {
            const it = itemAtIndex(win.selectedRow)
            if (it && it.kind === 1) {   // processus : remonter à son application
                for (let i = win.selectedRow; i >= 0; --i) { const g = itemAtIndex(i); if (g && g.kind === 0) { win.select(i); break } }
            } else procs.setExpanded(win.selectedKey, false)
        }
        Keys.onMenuPressed: { const it = itemAtIndex(win.selectedRow); if (it) win.openMenu(it, it.width - 240, it.height) }

        delegate: Rectangle {
            id: row
            required property int index
            required property string key
            required property int kind
            required property string name
            required property string icon
            required property int count
            required property double cpu
            required property double memory
            required property double disk
            required property int pid
            required property bool expanded
            required property bool own
            required property bool system
            required property bool lowPriority
            required property string command
            width: ListView.view.width
            height: kind === 0 ? 38 : 30
            readonly property bool selected: win.selectedKey === key
            color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : rowMouse.containsMouse ? Theme.surfaceHover : "transparent"
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Theme.border; opacity: 0.6 }

            Row {
                anchors { fill: parent; leftMargin: Theme.space4; rightMargin: Theme.space4 }
                Item {
                    width: parent.width - win.colWidth * 3; height: parent.height
                    Row {
                        anchors { left: parent.left; leftMargin: row.kind === 1 ? 44 : 0; verticalCenter: parent.verticalCenter }
                        spacing: Theme.space2
                        Item {
                            visible: row.kind === 0
                            width: 14; height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            Icon { anchors.fill: parent; name: row.expanded ? "expand" : "chevron-r"; color: Theme.textTertiary }
                            MouseArea { anchors { fill: parent; margins: -6 } onClicked: procs.toggleExpanded(row.key) }
                        }
                        Item {
                            visible: row.kind === 0
                            width: 22; height: 22
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                id: logo
                                anchors.fill: parent
                                sourceSize: Qt.size(44, 44)
                                source: row.icon ? (row.icon[0] === "/" ? "file://" + row.icon : "image://theme/" + row.icon) : ""
                                smooth: true
                                visible: status === Image.Ready && implicitWidth > 1
                            }
                            AppIcon { anchors.fill: parent; size: 22; iconName: row.system ? "chip" : "grid"; visible: !logo.visible }
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.name
                            font.pixelSize: row.kind === 0 ? Theme.fsMd : Theme.fsSm
                            font.weight: row.kind === 0 ? Font.Medium : Font.Normal
                            level: row.kind === 0 ? Label.Primary : Label.Secondary
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            level: Label.Tertiary
                            font.pixelSize: Theme.fsSm
                            text: row.kind === 0 ? (row.count > 1 ? qsTr("· %1 processus").arg(row.count) : "")
                                                 : qsTr("· n° %1").arg(row.pid) + (row.lowPriority ? " · " + qsTr("priorité basse") : "")
                        }
                    }
                }
                Repeater {
                    model: [
                        { column: ProcessModel.Cpu, value: row.cpu, text: win.percent(row.cpu) },
                        { column: ProcessModel.Memory, value: row.memory, text: win.bytes(row.memory) },
                        { column: ProcessModel.Disk, value: row.disk, text: win.rate(row.disk) }
                    ]
                    Item {
                        id: cell
                        required property var modelData
                        width: win.colWidth; height: row.height
                        readonly property int level: win.heat(modelData.column, modelData.value)
                        Rectangle {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width: value.implicitWidth + Theme.space2 * 2; height: 22
                            radius: Theme.radiusXs
                            color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, cell.level === 2 ? 0.26 : cell.level === 1 ? 0.12 : 0)
                            Label {
                                id: value
                                anchors.centerIn: parent
                                text: cell.modelData.text
                                font.pixelSize: row.kind === 0 ? Theme.fsMd : Theme.fsSm
                                font.weight: cell.level === 2 ? Font.DemiBold : Font.Normal
                                color: cell.level === 2 ? (Theme.dark ? "#F0C060" : "#8A5A00") : row.kind === 0 ? Theme.text : Theme.textSecondary
                            }
                        }
                    }
                }
            }
            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                z: -1
                onPressed: (m) => { win.selectedKey = row.key; list.forceActiveFocus() }
                onClicked: (m) => { if (m.button === Qt.RightButton) win.openMenu(row, m.x, m.y) }
                onDoubleClicked: if (row.kind === 0) procs.toggleExpanded(row.key)
            }
            Accessible.role: Accessible.Row
            Accessible.name: name + ", " + win.percent(cpu) + ", " + win.bytes(memory)
        }

        Label {
            anchors.centerIn: parent
            visible: list.count === 0
            level: Label.Tertiary
            text: qsTr("Aucune application ne correspond à « %1 ».").arg(search.text)
        }
    }

    // ---------- Application qui ne répond pas ----------
    Rectangle {
        id: notice
        visible: win.closingKey !== "" && !closeCheck.running
        anchors { left: parent.left; right: parent.right; bottom: footer.top }
        height: visible ? 46 : 0
        color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.16)
        Label {
            anchors { left: parent.left; leftMargin: Theme.space4; right: noticeButtons.left; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            elide: Text.ElideRight
            text: qsTr("« %1 » ne s'est pas fermée. Elle ne répond peut-être plus.").arg(win.closingName)
        }
        Row {
            id: noticeButtons
            anchors { right: parent.right; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
            spacing: Theme.space2
            Button { text: qsTr("Attendre"); variant: Button.Ghost; onClicked: win.closingKey = "" }
            Button { text: qsTr("Forcer la fermeture"); variant: Button.Primary; onClicked: { procs.forceClose(win.closingKey); win.closingKey = "" } }
        }
    }

    // ---------- Pied : action sur la sélection ----------
    Rectangle {
        id: footer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 52
        color: Theme.surfaceWindow
        Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: Theme.border }
        Label {
            anchors { left: parent.left; leftMargin: Theme.space4; right: footerButtons.left; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            level: Label.Tertiary
            font.pixelSize: Theme.fsSm
            elide: Text.ElideRight
            text: win.selectedRow < 0 ? qsTr("Sélectionnez une application. Clic droit pour plus d'actions.")
                : !win.selectionOwn ? qsTr("« %1 » est un service du système : il ne peut pas être fermé d'ici.").arg(procs.name(win.selectedKey))
                : qsTr("« %1 » sélectionnée · Suppr pour fermer").arg(procs.name(win.selectedKey))
        }
        Row {
            id: footerButtons
            anchors { right: parent.right; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
            spacing: Theme.space2
            Button { text: qsTr("Forcer la fermeture"); enabled: win.selectionOwn; onClicked: win.closeSelected(true) }
            Button { objectName: "closeButton"; text: qsTr("Fermer"); variant: Button.Primary; enabled: win.selectionOwn; onClicked: win.closeSelected(false) }
        }
    }

    // ---------- Menu contextuel ----------
    property var menuRow: null
    function openMenu(item, x, y) {
        menuRow = { key: item.key, own: item.own, low: item.lowPriority, kind: item.kind, pid: item.pid }
        const p = item.mapToItem(overlay, x, y)
        anchorPoint.x = p.x; anchorPoint.y = p.y
        menu.show(anchorPoint)
    }
    Item {
        id: overlay
        anchors.fill: parent
        Item { id: anchorPoint; width: 1; height: 1 }
        Menu {
            id: menu
            model: win.menuRow ? [
                { text: qsTr("Fermer"), shortcut: qsTr("Suppr"), enabled: win.menuRow.own, action: "close" },
                { text: qsTr("Forcer la fermeture"), shortcut: qsTr("Maj+Suppr"), enabled: win.menuRow.own, action: "kill" },
                { separator: true },
                win.menuRow.kind === 0 ? { text: win.menuRow.key === "system" ? qsTr("Voir les services") : qsTr("Voir les processus"), action: "expand" }
                                       : { text: qsTr("Copier le numéro (%1)").arg(win.menuRow.pid), action: "pid" },
                { text: qsTr("Copier la commande"), enabled: win.menuRow.own, action: "command" },
                { text: qsTr("Ouvrir l'emplacement du programme"), enabled: win.menuRow.own, action: "location" },
                { separator: true },
                { text: qsTr("Priorité basse"), checked: win.menuRow.low, enabled: win.menuRow.own && !win.menuRow.low, action: "nice" }
            ] : []
            onTriggered: (index, entry) => {
                const key = win.menuRow.key
                switch (entry.action) {
                case "close": win.selectedKey = key; win.closeSelected(false); break
                case "kill": win.selectedKey = key; win.closeSelected(true); break
                case "expand": procs.toggleExpanded(key); break
                case "pid": procs.copyText(String(win.menuRow.pid)); break
                case "command": procs.copyText(procs.command(key)); break
                case "location": { const dir = procs.location(key); if (dir) Qt.openUrlExternally("file://" + dir); break }
                case "nice": procs.lowerPriority(key); break
                }
            }
        }
    }
}
