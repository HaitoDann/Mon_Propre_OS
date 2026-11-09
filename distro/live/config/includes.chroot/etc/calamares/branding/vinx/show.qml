/* Diaporama affiché pendant l'installation de VinX OS. */
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 7000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    function onActivate() { }
    function onLeave() { }

    Slide {
        Rectangle { anchors.fill: parent; color: "#0D0B1A" }
        Image {
            id: logo
            source: "logo.png"
            width: 160; fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: parent.height * 0.18
        }
        Text {
            anchors.top: logo.bottom; anchors.topMargin: 32
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#EEF0F6"; font.pixelSize: 26; font.family: "Inter"
            text: "Bienvenue dans VinX OS"
        }
        Text {
            anchors.top: logo.bottom; anchors.topMargin: 78
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#A3A9B8"; font.pixelSize: 16; font.family: "Inter"
            text: "Simple. Ergonomique. Stable."
        }
    }

    Slide {
        Rectangle { anchors.fill: parent; color: "#0D0B1A" }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.7
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "#EEF0F6"; font.pixelSize: 20; font.family: "Inter"
            text: "Prêt à travailler dès le premier démarrage :\nFirefox, LibreOffice, Thunderbird et vos outils essentiels sont déjà installés."
        }
    }

    Slide {
        Rectangle { anchors.fill: parent; color: "#0D0B1A" }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.7
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "#EEF0F6"; font.pixelSize: 20; font.family: "Inter"
            text: "Ajoutez des fonctionnalités en un clic depuis le Store :\npacks développement, jeux, multimédia et graphisme."
        }
    }
}
