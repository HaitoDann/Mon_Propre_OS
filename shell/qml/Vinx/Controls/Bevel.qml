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
    // signature : garde le biseau même en style doux (logo, éléments de marque).
    property bool signature: false
    readonly property bool beveled: signature || Theme.shapeStyle === "bevel"
    readonly property real c: Math.max(0, Math.min(cut, width / 3, height / 3))
    // Style doux : quatre coins arrondis de rayon proche de la coupe.
    readonly property real r: beveled ? Math.min(corner, c) : Math.min(cut * 0.85, width / 2, height / 2)
    readonly property real h: borderWidth / 2
    // Animation signature : trait d'accent qui se dessine le long de la coupe (0 → 1).
    property real edgeProgress: 0
    property color edgeColor: Theme.accentForeground

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
            readonly property real k: 0.5523   // arc de cercle approché par une courbe de Bézier
            function arc(xa, ya, cx, cy, xb, yb) {
                return "C" + (xa + (cx - xa) * k) + " " + (ya + (cy - ya) * k) + " "
                     + (xb + (cx - xb) * k) + " " + (yb + (cy - yb) * k) + " " + xb + " " + yb
            }
            path: root.beveled
                ? "M" + (x0 + root.r) + " " + y0
                  + "H" + (x1 - root.c) + "L" + x1 + " " + (y0 + root.c)
                  + "V" + (y1 - root.r) + "Q" + x1 + " " + y1 + " " + (x1 - root.r) + " " + y1
                  + "H" + (x0 + root.c) + "L" + x0 + " " + (y1 - root.c)
                  + "V" + (y0 + root.r) + "Q" + x0 + " " + y0 + " " + (x0 + root.r) + " " + y0 + "Z"
                : "M" + (x0 + root.r) + " " + y0
                  + "H" + (x1 - root.r) + arc(x1 - root.r, y0, x1, y0, x1, y0 + root.r)
                  + "V" + (y1 - root.r) + arc(x1, y1 - root.r, x1, y1, x1 - root.r, y1)
                  + "H" + (x0 + root.r) + arc(x0 + root.r, y1, x0, y1, x0, y1 - root.r)
                  + "V" + (y0 + root.r) + arc(x0, y0 + root.r, x0, y0, x0 + root.r, y0) + "Z"
        }
    }
    ShapePath {
        strokeColor: root.edgeProgress > 0 ? root.edgeColor : "transparent"
        strokeWidth: 2
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        // Biseau : le long de la coupe. Doux : un court trait sur le bord haut, près du coin.
        startX: root.beveled ? root.width - root.c - 1 : root.width - root.r - 28
        startY: 1
        PathLine {
            x: root.beveled ? root.width - root.c - 1 + root.c * root.edgeProgress : root.width - root.r - 28 + 28 * root.edgeProgress
            y: root.beveled ? 1 + root.c * root.edgeProgress : 1
        }
    }
}
