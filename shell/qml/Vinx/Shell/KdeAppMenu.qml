import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System
import org.kde.plasma.private.appmenu 1.0 as AppMenuPrivate

// Menu global de l'application active (Fichier, Édition…), exporté en DBusMenu.
// Chargé dynamiquement par TopBar : absent si le module KDE n'est pas installé.
Row {
    id: root
    spacing: 0
    visible: model.visible && model.menuAvailable

    AppMenuPrivate.AppMenuModel { id: model }

    Repeater {
        model: model
        delegate: TopBarButton {
            id: btn
            required property string activeMenu
            required property var activeActions
            Label { text: MenuBridge.plainText(btn.activeMenu); anchors.verticalCenter: parent.verticalCenter }
            panel: "appmenu"
            menuAction: btn.activeActions
        }
    }
}
