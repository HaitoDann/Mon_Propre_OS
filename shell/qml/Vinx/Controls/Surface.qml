import QtQuick
import Vinx.Theme

// Matériau du shell (barre, dock, menus, panneaux) : forme biseautée VinX.
// Le flou d'arrière-plan est fourni par KWin (effet « blur ») sur les surfaces du shell ;
// la surface ne dessine que sa teinte, sa bordure et son ombre.
Item {
    id: root
    enum Kind { Glass, Strong, Window, Sunken }
    property int kind: Surface.Glass
    property int elevation: 1
    property real radius: Theme.radiusLg
    // Couleur de bordure imposée (ex. notification critique) ; sinon celle du matériau.
    property color borderColor: kind === Surface.Strong ? Theme.borderStrong : Theme.border
    readonly property color color: kind === Surface.Strong ? Theme.surfaceGlassStrong
         : kind === Surface.Window ? Theme.surfaceWindow
         : kind === Surface.Sunken ? Theme.surfaceSunken : Theme.surfaceGlass

    Elevation { anchors.fill: parent; radius: Theme.radiusXs; level: root.elevation }
    Bevel {
        anchors.fill: parent
        cut: root.radius
        color: root.color
        borderWidth: 1
        borderColor: root.borderColor
    }
}
