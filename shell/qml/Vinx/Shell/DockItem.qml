import QtQuick
import Vinx.Theme
import Vinx.Controls
import "AppStyle.js" as AppStyle

// Icône du dock : agrandissement selon la distance au pointeur, indicateur d'ouverture.
Item {
    id: item
    property string appId
    property string appName
    property bool running: false
    property bool active: false
    property int windows: 0
    property real pointerX: -1          // position du pointeur dans coordItem (-1 : hors du dock)
    property Item coordItem: parent
    property bool magnify: true
    signal clicked()
    signal contextRequested()

    readonly property var style: AppStyle.forApp(appId)
    readonly property real base: Theme.dockIcon
    readonly property real size: {
        if (!magnify || pointerX < 0) return base
        const c = mapToItem(coordItem, width / 2, 0).x
        const d = Math.abs(pointerX - c)
        const range = base * 3
        const k = d > range ? 0 : (Math.cos(d / range * Math.PI) + 1) / 2
        return base + (Theme.dockIconMax - base) * k
    }

    width: size
    height: base
    Behavior on width { enabled: item.pointerX < 0; NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }

    Accessible.role: Accessible.Button
    Accessible.name: appName

    Item {
        id: icon
        width: item.size; height: item.size
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        scale: mouse.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: Theme.durFast } }

        AppIcon {
            anchors.fill: parent
            visible: item.style !== null
            size: item.size
            iconName: item.style ? item.style.glyph : ""
            tint: item.style ? item.style.tint : "#5F6270"
        }
        // Applications sans icône VinX : icône de leur thème, sur une pastille neutre.
        Rectangle {
            anchors.fill: parent
            visible: item.style === null
            radius: width * 0.23
            color: Theme.surfaceActive
            Image {
                anchors.centerIn: parent
                width: parent.width * 0.72; height: width
                sourceSize: Qt.size(width * 2, height * 2)
                source: item.style === null && item.appId ? "image://theme/" + item.appId : ""
                smooth: true
            }
        }
    }

    // Indicateur : un point par fenêtre (deux au maximum), plus marqué pour l'app active.
    Row {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 3 }
        spacing: 3
        Repeater {
            model: item.running ? Math.min(2, Math.max(1, item.windows)) : 0
            Rectangle {
                width: 4; height: 4; radius: 2
                color: Theme.text
                opacity: item.active ? 0.9 : 0.45
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        onClicked: (m) => m.button === Qt.RightButton ? item.contextRequested() : item.clicked()
    }
    readonly property bool hovered: mouse.containsMouse
}
