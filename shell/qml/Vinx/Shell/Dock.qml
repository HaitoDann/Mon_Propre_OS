import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import "AppStyle.js" as AppStyle

// Dock centré en bas (ou à gauche, vertical) : applications épinglées | séparateur | applications ouvertes non épinglées.
// Remplit sa fenêtre ; le plateau est ancré en bas. screenOffset convertit vers les coordonnées écran.
Item {
    id: dock
    property var backend: Tasks.backend
    readonly property int rev: Preferences.revision
    // Réglages (Paramètres → Dock) : taille des icônes 40–64 px, agrandissement au survol.
    readonly property int iconSize: { rev; return Math.max(40, Math.min(64, Number(Preferences.value("dock/iconSize", Theme.dockIcon)))) }
    // Position (Paramètres → Dock) : en bas (par défaut) ou à gauche, vertical. L'agrandissement
    // au survol n'existe qu'en bas.
    readonly property bool vertical: { rev; return String(Preferences.value("dock/position", "bottom")) === "left" }
    readonly property bool magnify: { rev; const v = Preferences.value("dock/magnify", true); return !vertical && (v === true || v === "true") }
    property point screenOffset: Qt.point(0, 0)
    readonly property real margin: Theme.space2
    readonly property real plateHeight: iconSize + Theme.space3 + 2
    // Hauteur réservée en bas de l'écran (zone que les fenêtres agrandies ne recouvrent pas).
    readonly property int reservedHeight: plateHeight + margin * 2

    // Masquage automatique (Paramètres → Dock) : le dock glisse sous le bord de l'écran et
    // revient quand le pointeur touche le bas de l'écran. Il ne réserve alors plus de place.
    readonly property bool autohide: { rev; const v = Preferences.value("dock/autohide", false); return v === true || v === "true" }
    property bool shown: true
    readonly property bool wantShown: !autohide || hover.hovered || ShellState.openPanel === "dock"
    onWantShownChanged: if (wantShown) { hideDelay.stop(); shown = true } else hideDelay.restart()
    onAutohideChanged: shown = wantShown
    Timer { id: hideDelay; interval: 700; onTriggered: dock.shown = dock.wantShown }
    property real hideOffset: shown ? 0 : reservedHeight + 8   // vers le bas, ou vers la gauche en vertical
    Behavior on hideOffset { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }
    // Lus par vinx-shell (main.cpp) : zone réservée et zone qui reçoit le pointeur.
    readonly property int exclusiveZone: autohide ? 0 : reservedHeight
    readonly property rect inputRect: shown ? Qt.rect(0, 0, width, height)
                                            : vertical ? Qt.rect(0, 0, 4, height) : Qt.rect(0, height - 4, width, 4)

    // Icône à la position i (tests, aperçu).
    function itemAt(i) { const c = rep.itemAt(i); return c ? c.children[1] : null }

    function rectOf(it) {
        const p = it.mapToItem(null, 0, 0)
        return Qt.rect(p.x + screenOffset.x, p.y + screenOffset.y, it.width, it.height)
    }

    Surface {
        id: plate
        kind: Surface.Glass
        elevation: 1
        radius: Theme.radiusXl
        height: dock.vertical ? row.height + Theme.space3 * 2 : dock.plateHeight
        width: dock.vertical ? dock.plateHeight : row.width + Theme.space3 * 2
        x: dock.vertical ? dock.margin : (parent.width - width) / 2
        y: dock.vertical ? (parent.height - height) / 2 : parent.height - height - dock.margin
        transform: Translate { x: dock.vertical ? -dock.hideOffset : 0; y: dock.vertical ? 0 : dock.hideOffset }
    }

    // Position du pointeur dans le dock (coordonnées du Dock), pour l'agrandissement.
    HoverHandler { id: hover }

    Grid {
        id: row
        spacing: Theme.space2
        columns: dock.vertical ? 1 : -1
        rows: dock.vertical ? -1 : 1
        verticalItemAlignment: Grid.AlignBottom
        horizontalItemAlignment: Grid.AlignHCenter
        x: dock.vertical ? plate.x + (plate.width - width) / 2 : (parent.width - width) / 2
        y: dock.vertical ? plate.y + Theme.space3 : plate.y + plate.height - height - Theme.space2 - 2
        transform: Translate { x: dock.vertical ? -dock.hideOffset : 0; y: dock.vertical ? 0 : dock.hideOffset }

        Repeater {
            id: rep
            model: dock.backend ? dock.backend.model : null
            delegate: Grid {
                id: cell
                required property int index
                required property var model
                spacing: Theme.space2
                columns: dock.vertical ? 1 : -1
                rows: dock.vertical ? -1 : 1
                verticalItemAlignment: Grid.AlignVCenter
                horizontalItemAlignment: Grid.AlignHCenter

                // Séparateur avant la première application ouverte non épinglée.
                Rectangle {
                    visible: cell.index === dock.backend.pinnedCount && cell.index > 0
                    width: dock.vertical ? dock.iconSize - 8 : 1
                    height: dock.vertical ? 1 : dock.iconSize - 8
                    color: Theme.borderStrong
                }
                DockItem {
                    id: icon
                    appId: AppStyle.normalizeId(cell.model.AppId, cell.model.LauncherUrlWithoutIcon)
                    appName: cell.model.AppName || cell.model.display || appId
                    running: !!cell.model.IsWindow || cell.model.ChildCount > 0
                    active: !!cell.model.IsActive
                    windows: cell.model.ChildCount > 0 ? cell.model.ChildCount : (cell.model.IsWindow ? 1 : 0)
                    magnify: dock.magnify
                    base: dock.iconSize
                    coordItem: row
                    pointerX: hover.hovered ? row.mapFromItem(dock, hover.point.position.x, 0).x : -1
                    onClicked: { ShellState.close(); dock.backend.activate(cell.index) }
                    onContextRequested: ShellState.openDockMenu(cell.index, appName, running, dock.backend.isPinned(cell.index), dock.rectOf(icon),
                                                                 Window.window && Window.window.screen ? Window.window.screen.name : "")
                    onHoveredChanged: if (hovered) tip.show(icon); else if (tip.target === icon) tip.target = null
                }
            }
        }
    }

    // Infobulle au-dessus de l'icône survolée.
    Surface {
        id: tip
        property Item target: null
        function show(t) { target = t }
        kind: Surface.Strong
        elevation: 1
        radius: Theme.radiusSm
        visible: target !== null && ShellState.openPanel === ""
        width: tipLabel.implicitWidth + Theme.space3 * 2
        height: 26
        x: !target ? 0 : dock.vertical ? plate.x + plate.width + Theme.space3 : target.mapToItem(dock, target.width / 2, 0).x - width / 2
        y: !target ? 0 : dock.vertical ? target.mapToItem(dock, 0, target.height / 2).y - height / 2
                                       : plate.y - height - Theme.space3 - (dock.magnify ? dock.iconSize * 0.33 : 0)
        Label { id: tipLabel; anchors.centerIn: parent; text: tip.target ? tip.target.appName : ""; font.pixelSize: Theme.fsSm }
    }
}
