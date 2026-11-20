import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Espaces de travail (ADR 0044) : bouton discret de la barre. Un point par espace (bureau virtuel de
// KWin), le courant allongé, suivi du nom de l'espace courant quand il a été renommé.
// Clic : menu des espaces. Molette : espace précédent / suivant.
TopBarButton {
    id: ind
    objectName: "spacesButton"
    panel: "spaces"
    spacing: 5
    readonly property var backend: Tasks.backend
    readonly property int count: backend ? backend.desktopCount : 0
    readonly property int current: backend ? backend.currentDesktopIndex : 0
    readonly property string currentName: backend && backend.desktopNames ? String(backend.desktopNames[current] || "") : ""
    // Nom affiché seulement s'il a été choisi (pas « Bureau 2 », nom par défaut de KWin).
    readonly property bool customName: currentName !== "" && !/^(Bureau|Desktop) \d+$/.test(currentName)

    readonly property color dotCurrent: Theme.text
    readonly property color dotOther: Theme.textTertiary
    Accessible.name: qsTr("Espaces : %1 (%2 sur %3)").arg(currentName).arg(current + 1).arg(Math.max(1, count))

    Repeater {
        model: Math.max(1, ind.count)
        Rectangle {
            required property int index
            readonly property bool isCurrent: index === ind.current
            width: isCurrent ? 14 : 6
            height: 6
            radius: 3
            anchors.verticalCenter: parent.verticalCenter
            // Dès qu'un espace a une couleur (ADR 0044) : chaque point prend celle de son espace (vert par
            // défaut) ; sinon encre / gris comme avant.
            readonly property string fill: (ShellState.spaceColors, ind.backend ? ind.backend.desktopIds : 0, ShellState.anySpaceColored ? ShellState.spaceFillOrGlobal(index) : "")
            color: fill !== "" ? fill : isCurrent ? ind.dotCurrent : ind.dotOther
            opacity: fill !== "" && !isCurrent ? 0.55 : 1
            Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }
        }
    }
    Label {
        visible: ind.customName
        anchors.verticalCenter: parent.verticalCenter
        text: ind.currentName
        font.pixelSize: Theme.fsSm
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 140)
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse
        onWheel: (e) => {
            if (!ind.backend || ind.count < 2) return
            const next = ind.current + (e.angleDelta.y < 0 ? 1 : -1)
            if (next >= 0 && next < ind.count) ind.backend.activateDesktop(next)
        }
    }
}
