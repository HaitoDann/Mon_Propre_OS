import QtQuick

// Couche plein écran transparente qui accueille les panneaux de la barre.
// Visible uniquement quand un panneau est ouvert ; un clic hors panneau le ferme.
Window {
    color: "transparent"
    visible: ShellState.openPanel !== ""
    title: "vinx-panels"
    Panels { anchors.fill: parent }
}
