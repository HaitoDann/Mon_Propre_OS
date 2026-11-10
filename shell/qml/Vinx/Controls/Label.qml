import QtQuick
import Vinx.Theme

// Texte à la charte : police, taille et couleur issues du thème.
Text {
    enum Level { Primary, Secondary, Tertiary }
    property int level: Label.Primary

    color: level === Label.Secondary ? Theme.textSecondary
         : level === Label.Tertiary ? Theme.textTertiary : Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fsMd
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
