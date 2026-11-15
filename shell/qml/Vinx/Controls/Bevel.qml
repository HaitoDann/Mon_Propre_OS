import QtQuick
import QtQuick.Shapes
import Vinx.Theme

// Forme signature de VinX : rectangle aux coins haut-droit et bas-gauche coupés en biseau,
// reprise de l'angle du logo V/X. Utilisée par les surfaces, boutons, tuiles et le dock.
Shape {
    id: root
    property color color: "transparent"
    property color borderColor: "transparent"
    property real borderWidth: 0
    // Taille de la coupe ; les deux autres coins gardent un léger arrondi.
    property real cut: 8
    property real corner: 2
    readonly property real c: Math.max(0, Math.min(cut, width / 3, height / 3))
    readonly property real r: Math.min(corner, c)
    readonly property real h: borderWidth / 2

    ShapePath {
        fillColor: root.color
        strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
        strokeWidth: root.borderWidth
        joinStyle: ShapePath.MiterJoin
        PathSvg {
            readonly property real x0: root.h
            readonly property real y0: root.h
            readonly property real x1: root.width - root.h
            readonly property real y1: root.height - root.h
            path: "M" + (x0 + root.r) + " " + y0
                + "H" + (x1 - root.c) + "L" + x1 + " " + (y0 + root.c)
                + "V" + (y1 - root.r) + "Q" + x1 + " " + y1 + " " + (x1 - root.r) + " " + y1
                + "H" + (x0 + root.c) + "L" + x0 + " " + (y1 - root.c)
                + "V" + (y0 + root.r) + "Q" + x0 + " " + y0 + " " + (x0 + root.r) + " " + y0 + "Z"
        }
    }
}
