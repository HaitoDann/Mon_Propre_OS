import QtQuick
import Vinx.Theme

// Matériau du shell (barre, dock, menus, panneaux).
// Le flou d'arrière-plan sera fourni par KWin (effet « blur ») sur les surfaces du shell ;
// la surface ne dessine que sa teinte translucide, sa bordure et son ombre.
Rectangle {
    enum Kind { Glass, Strong, Window, Sunken }
    property int kind: Surface.Glass
    property int elevation: 1

    radius: Theme.radiusLg
    color: kind === Surface.Strong ? Theme.surfaceGlassStrong
         : kind === Surface.Window ? Theme.surfaceWindow
         : kind === Surface.Sunken ? Theme.surfaceSunken : Theme.surfaceGlass
    border.width: 1
    border.color: kind === Surface.Strong ? Theme.borderStrong : Theme.border

    Behavior on color { ColorAnimation { duration: Theme.durNormal } }

    Elevation { anchors.fill: parent; radius: parent.radius; level: parent.elevation }
}
