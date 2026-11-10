import QtQuick
import Vinx.Theme

// Menu déroulant construit depuis un modèle :
// [{ text, shortcut, iconName, enabled, checked }, { separator: true }, { header: "Titre" }]
Popover {
    id: menu
    property var model: []
    signal triggered(int index, var entry)

    Column {
        id: col
        property real minWidth: 220
        width: minWidth
        Repeater {
            model: menu.model
            MenuItem {
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
