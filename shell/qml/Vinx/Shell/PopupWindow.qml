import QtQuick

// Couche plein écran transparente qui accueille les panneaux de la barre.
// Visible uniquement quand un panneau est ouvert ; un clic hors panneau le ferme.
Window {
    color: "transparent"
    // Un exemplaire par écran : ne s'affiche que sur l'écran du panneau demandé
    // (l'écran principal si la demande ne vient d'aucun écran, ex. touche Méta).
    property bool isPrimary: true
    visible: ShellState.openPanel !== ""
             && (ShellState.screenName === "" ? isPrimary : !!screen && ShellState.screenName === screen.name)
    title: "vinx-panels"
    Panels { anchors.fill: parent }
}
