import QtQuick
import Vinx.Theme
import Vinx.Controls

// Logo d'un logiciel : icône AppStream (Debian) ou Flathub, sinon icône du thème, sinon initiales
// sur une tuile à la couleur du rayon.
Item {
    id: root
    property string iconUrl
    property string themeIcon
    property string name
    property color tint: "#9AA09C"
    property real size: 52
    width: size; height: size

    Image {
        id: img
        anchors.fill: parent
        source: root.iconUrl ? root.iconUrl : root.themeIcon ? "image://theme/" + root.themeIcon : ""
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        asynchronous: true
        smooth: true
        visible: status === Image.Ready && implicitWidth > 1
    }
    Rectangle {
        anchors.fill: parent
        visible: !img.visible
        radius: root.size * 0.24
        color: root.tint
        Label {
            anchors.centerIn: parent
            // Deux premières lettres significatives (« LibreOffice Writer » → « LW »).
            text: {
                const w = (root.name || "?").replace(/[^A-Za-zÀ-ÿ0-9 ]/g, " ").trim().split(/\s+/)
                return (w.length > 1 ? w[0][0] + w[1][0] : w[0].slice(0, 2)).toUpperCase()
            }
            color: "#FFFFFF"
            font.pixelSize: root.size * 0.36
            font.weight: Font.Bold
        }
    }
}
