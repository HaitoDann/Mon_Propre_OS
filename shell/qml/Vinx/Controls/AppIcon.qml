import QtQuick
import QtQuick.Shapes
import Vinx.Theme
import Vinx.Controls  // types C++ du module (Icon) — import explicite requis avant Qt 6.5

// Icône d'application VinX : silhouette de l'objet (dossier, page, enveloppe, globe…)
// d'une teinte unie et sobre, pictogramme blanc au trait. Identique au thème d'icônes système.
Item {
    id: root
    property string iconName
    property color tint: "#6B6E76"
    property real size: Theme.dockIcon
    property string shape: shapes.byGlyph[iconName] || "circle"
    // Silhouettes (grille 64 × 64) : mêmes valeurs que branding/icon-theme/gen_icons.py
    // (thème d'icônes système) — à modifier ensemble.
    readonly property QtObject shapes: QtObject {
        readonly property var paths: ({
            folder:   "M6 16a4 4 0 0 1 4-4h14l5 5h25a4 4 0 0 1 4 4v29a4 4 0 0 1-4 4H10a4 4 0 0 1-4-4Z",
            page:     "M14 6h24l14 14v34a4 4 0 0 1-4 4H14a4 4 0 0 1-4-4V10a4 4 0 0 1 4-4Z",
            circle:   "M32 5a27 27 0 1 1 0 54a27 27 0 1 1 0-54Z",
            envelope: "M8 14h48a4 4 0 0 1 4 4v28a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4V18a4 4 0 0 1 4-4Z",
            window:   "M10 8h44a5 5 0 0 1 5 5v38a5 5 0 0 1-5 5H10a5 5 0 0 1-5-5V13a5 5 0 0 1 5-5Z",
            bag:      "M14 20h36l3 32a5 5 0 0 1-5 6H16a5 5 0 0 1-5-6Z"
        })
        readonly property string pageFold: "M38 6v10a4 4 0 0 0 4 4h10Z"
        readonly property string folderFront: "M6 24a4 4 0 0 1 4-4h44a4 4 0 0 1 4 4v26a4 4 0 0 1-4 4H10a4 4 0 0 1-4-4Z"
        // Zone du pictogramme : [x, y, taille].
        readonly property var glyphBox: ({ folder: [19, 23, 26], page: [19, 26, 26], circle: [17, 17, 30],
                                           envelope: [19, 19, 26], window: [19, 20, 26], bag: [20, 27, 24] })
        readonly property var byGlyph: ({ folder: "folder", doc: "page", table: "page", note: "page", mail: "envelope",
                                          terminal: "window", bag: "bag", image: "window" })
    }

    implicitWidth: size; implicitHeight: size
    readonly property real k: width / 64
    readonly property var box: shapes.glyphBox[shape] || shapes.glyphBox.circle

    Shape {
        anchors.fill: parent
        transform: Scale { xScale: root.k; yScale: root.k }
        ShapePath {
            fillColor: root.tint
            strokeColor: "transparent"
            PathSvg { path: root.shapes.paths[root.shape] || root.shapes.paths.circle }
        }
        ShapePath {
            fillColor: root.shape === "page" ? Qt.lighter(root.tint, 1.35)
                     : root.shape === "folder" ? Qt.lighter(root.tint, 1.1) : "transparent"
            strokeColor: "transparent"
            PathSvg { path: root.shape === "page" ? root.shapes.pageFold : root.shape === "folder" ? root.shapes.folderFront : "" }
        }
    }
    Icon {
        x: root.box[0] * root.k; y: root.box[1] * root.k
        width: root.box[2] * root.k; height: width
        name: root.iconName
        color: "white"
    }
}
