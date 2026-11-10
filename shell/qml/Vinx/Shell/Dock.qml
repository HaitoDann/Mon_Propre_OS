import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import "AppStyle.js" as AppStyle

// Dock centré en bas : applications épinglées | séparateur | applications ouvertes non épinglées.
// Remplit sa fenêtre ; le plateau est ancré en bas. screenOffset convertit vers les coordonnées écran.
Item {
    id: dock
    property var backend: Tasks.backend
    readonly property int rev: Preferences.revision
    // Réglages (Paramètres → Dock) : taille des icônes 40–64 px, agrandissement au survol.
    readonly property int iconSize: { rev; return Math.max(40, Math.min(64, Number(Preferences.value("dock/iconSize", Theme.dockIcon)))) }
    readonly property bool magnify: { rev; const v = Preferences.value("dock/magnify", true); return v === true || v === "true" }
    property point screenOffset: Qt.point(0, 0)
    readonly property real margin: Theme.space2
    readonly property real plateHeight: iconSize + Theme.space3 + 2
    // Hauteur réservée en bas de l'écran (zone que les fenêtres agrandies ne recouvrent pas).
    readonly property int reservedHeight: plateHeight + margin * 2

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
        height: dock.plateHeight
        width: row.width + Theme.space3 * 2
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: dock.margin }
    }

    // Position du pointeur dans le dock (coordonnées du Dock), pour l'agrandissement.
    HoverHandler { id: hover }

    Row {
        id: row
        spacing: Theme.space2
        anchors { horizontalCenter: plate.horizontalCenter; bottom: plate.bottom; bottomMargin: Theme.space2 + 2 }

        Repeater {
            id: rep
            model: dock.backend ? dock.backend.model : null
            delegate: Row {
                id: cell
                required property int index
                required property var model
                spacing: Theme.space2
                anchors.bottom: parent ? parent.bottom : undefined

                // Séparateur avant la première application ouverte non épinglée.
                Rectangle {
                    visible: cell.index === dock.backend.pinnedCount && cell.index > 0
                    width: 1; height: dock.iconSize - 8
                    anchors.verticalCenter: icon.verticalCenter
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
        x: target ? target.mapToItem(dock, target.width / 2, 0).x - width / 2 : 0
        y: plate.y - height - Theme.space3 - (dock.magnify ? dock.iconSize * 0.33 : 0)
        Label { id: tipLabel; anchors.centerIn: parent; text: tip.target ? tip.target.appName : ""; font.pixelSize: Theme.fsSm }
    }
}
