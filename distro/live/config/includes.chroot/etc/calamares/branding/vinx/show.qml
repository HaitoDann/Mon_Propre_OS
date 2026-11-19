/* Diaporama affiché pendant l'installation de VinX OS.
 * Charte (docs/DESIGN.md § 6) : fond clair, logo vert, IBM Plex Sans, texte à l'encre.
 * Langue : celle choisie dans l'installateur (Calamares règle la langue de Qt) ; français par
 * défaut, anglais pour toute autre langue. */
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    readonly property bool fr: (Qt.uiLanguage || Qt.locale().name).indexOf("fr") === 0
    function t(fr, en) { return presentation.fr ? fr : en }

    readonly property color background: "#ECEBE6"
    readonly property color ink: "#141414"
    readonly property color secondary: "#5F5E5A"
    readonly property color accentText: "#0A7A4E"

    Timer {
        interval: 7000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    function onActivate() { }
    function onLeave() { }

    Slide {
        Rectangle { anchors.fill: parent; color: presentation.background }
        Image {
            id: logo
            source: "logo.png"
            width: 140; fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: parent.height * 0.18
        }
        Text {
            anchors.top: logo.bottom; anchors.topMargin: 32
            anchors.horizontalCenter: parent.horizontalCenter
            color: presentation.ink; font.pixelSize: 26; font.weight: Font.DemiBold; font.family: "IBM Plex Sans"
            text: presentation.t("Bienvenue dans VinX OS", "Welcome to VinX OS")
        }
        Text {
            anchors.top: logo.bottom; anchors.topMargin: 78
            anchors.horizontalCenter: parent.horizontalCenter
            color: presentation.secondary; font.pixelSize: 16; font.family: "IBM Plex Sans"
            text: presentation.t("Simple. Ergonomique. Stable.", "Simple. Ergonomic. Stable.")
        }
    }

    Slide {
        Rectangle { anchors.fill: parent; color: presentation.background }
        Column {
            anchors.centerIn: parent
            width: parent.width * 0.7
            spacing: 14
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                color: presentation.ink; font.pixelSize: 22; font.weight: Font.DemiBold; font.family: "IBM Plex Sans"
                text: presentation.t("Prêt à travailler dès le premier démarrage", "Ready to work from the first start")
            }
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                color: presentation.secondary; font.pixelSize: 16; font.family: "IBM Plex Sans"
                text: presentation.t("Firefox, LibreOffice, Thunderbird et vos outils essentiels sont déjà installés.",
                                     "Firefox, LibreOffice, Thunderbird and your essential tools are already installed.")
            }
        }
    }

    Slide {
        Rectangle { anchors.fill: parent; color: presentation.background }
        Column {
            anchors.centerIn: parent
            width: parent.width * 0.7
            spacing: 14
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                color: presentation.ink; font.pixelSize: 22; font.weight: Font.DemiBold; font.family: "IBM Plex Sans"
                text: presentation.t("Des milliers de logiciels dans le Store", "Thousands of apps in the Store")
            }
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                color: presentation.secondary; font.pixelSize: 16; font.family: "IBM Plex Sans"
                text: presentation.t("Bureautique, graphisme, jeux, développement : installez-les en un clic, depuis Debian ou Flathub.",
                                     "Office, graphics, games, development: install them in one click, from Debian or Flathub.")
            }
        }
    }

    Slide {
        Rectangle { anchors.fill: parent; color: presentation.background }
        Column {
            anchors.centerIn: parent
            width: parent.width * 0.7
            spacing: 14
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                color: presentation.ink; font.pixelSize: 22; font.weight: Font.DemiBold; font.family: "IBM Plex Sans"
                text: presentation.t("Retour en arrière après une mise à jour", "Roll back after an update")
            }
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                color: presentation.secondary; font.pixelSize: 16; font.family: "IBM Plex Sans"
                text: presentation.t("Un instantané du système est pris avant chaque mise à jour. En cas de souci, choisissez « revenir à un état précédent » au démarrage.",
                                     "A system snapshot is taken before every update. If something goes wrong, choose \"go back to a previous state\" at startup.")
            }
        }
    }
}
