import QtQuick
import Vinx.Theme
import Vinx.Controls

// Icône d'un élément : miniature pour les images locales, sinon icône du thème
// (type de fichier), sinon pictogramme VinX.
Item {
    id: root
    property string iconName
    property url url
    property bool isDir
    property bool isImage
    property real size: 48

    width: size; height: size
    Image {
        id: thumb
        anchors.fill: parent
        visible: root.isImage && status === Image.Ready
        source: root.isImage ? root.url : ""
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false
    }
    Image {
        id: themed
        anchors.fill: parent
        visible: !thumb.visible && status === Image.Ready && implicitWidth > 1
        source: root.iconName ? "image://theme/" + root.iconName : ""
        sourceSize: Qt.size(root.size, root.size)
        asynchronous: true
    }
    Icon {
        visible: !thumb.visible && !themed.visible
        anchors.centerIn: parent
        width: root.size * 0.7; height: width
        name: root.isDir ? "folder" : root.isImage ? "image" : "doc"
        color: root.isDir ? Theme.accentForeground : Theme.textSecondary
    }
}
