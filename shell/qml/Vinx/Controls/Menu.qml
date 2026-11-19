import QtQuick
import Vinx.Theme

// Menu déroulant construit depuis un modèle :
// [{ text, shortcut, iconName, enabled, checked }, { separator: true }, { header: "Titre" }]
Popover {
    id: menu
    property var model: []
    signal triggered(int index, var entry)

    // Clavier (DESIGN § 7 « Tout au clavier ») : ↑/↓ (Début/Fin) parcourent les entrées actives,
    // Entrée ou Espace choisit, Échap ferme (Popover). Le survol à la souris déplace aussi la sélection.
    property int current: -1
    onOpenChanged: current = -1
    function step(from, dir) {
        const n = rep.count
        for (let k = 1; k <= n; ++k) {
            const i = ((from + dir * k) % n + n) % n
            const it = rep.itemAt(i)
            if (it && it.interactive) return i
        }
        return -1
    }
    function activate() {
        const it = rep.itemAt(current)
        if (it && it.interactive) it.triggered()
    }
    Keys.onDownPressed: current = step(current < 0 ? -1 : current, 1)
    Keys.onUpPressed: current = step(current < 0 ? 0 : current, -1)
    Keys.onTabPressed: current = step(current < 0 ? -1 : current, 1)
    Keys.onBacktabPressed: current = step(current < 0 ? 0 : current, -1)
    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_Home) { current = step(-1, 1); e.accepted = true }
        else if (e.key === Qt.Key_End) { current = step(0, -1); e.accepted = true }
    }
    Keys.onReturnPressed: activate()
    Keys.onEnterPressed: activate()
    Keys.onSpacePressed: activate()

    Column {
        id: col
        property real minWidth: 220
        width: minWidth
        Repeater {
            id: rep
            model: menu.model
            MenuItem {
                current: index === menu.current
                onHoveredChanged: if (hovered && interactive) menu.current = index
                width: col.width
                text: modelData.header || modelData.text || ""
                header: !!modelData.header
                separator: !!modelData.separator
                iconName: modelData.iconName || ""
                shortcut: modelData.shortcut || ""
                checked: modelData.checked
                enabled: modelData.enabled !== false
                onImplicitWidthChanged: col.minWidth = Math.max(col.minWidth, implicitWidth)
                onTriggered: { menu.close(); menu.triggered(index, modelData) }
            }
        }
    }
}
