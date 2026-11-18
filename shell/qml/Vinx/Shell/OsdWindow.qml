import QtQuick
import Vinx.Theme

// Surface des bulles volume/luminosité (layer-shell, en bas au centre, sans clic ni clavier).
Window {
    width: osd.width + Theme.space4 * 2
    height: osd.height + Theme.space4 * 2
    color: "transparent"
    visible: false
    title: "vinx-osd"
    Osd { id: osd; anchors.centerIn: parent }
}
