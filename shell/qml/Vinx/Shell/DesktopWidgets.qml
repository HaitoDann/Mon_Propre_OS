import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Widgets optionnels du bureau : Horloge, Calendrier, Note rapide (désactivés sauf l'horloge).
Item {
    id: widgets
    readonly property int rev: Preferences.revision
    function isOn(k, def) { rev; const v = Preferences.value("widgets/" + k, def); return v === true || v === "true" }
    property date now: new Date()
    Timer { interval: 15000; running: true; repeat: true; onTriggered: widgets.now = new Date() }

    readonly property real firstY: Theme.topbarHeight + Theme.space5

    // Position par défaut : chaque widget visible se place sous le précédent.
    Widget {
        id: clockW
        key: "clock"
        visible: widgets.isOn("clock", true)
        defaultPosition: Qt.point(Theme.space5, widgets.firstY)
        Column {
            spacing: Theme.space1
            Label { text: Qt.formatTime(widgets.now, "HH:mm"); font.pixelSize: Theme.fsDisplay; font.weight: Font.Light }
            Label {
                text: { const s = widgets.now.toLocaleDateString(Qt.locale(), "dddd d MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
                level: Label.Secondary
            }
        }
    }

    Widget {
        id: calendarW
        key: "calendar"
        visible: widgets.isOn("calendar", false)
        defaultPosition: Qt.point(Theme.space5, clockW.visible ? clockW.y + clockW.height + Theme.space4 : widgets.firstY)
        CalendarGrid { width: parent.width; compact: true }
    }

    Widget {
        key: "note"
        visible: widgets.isOn("note", false)
        defaultPosition: Qt.point(Theme.space5, calendarW.visible ? calendarW.y + calendarW.height + Theme.space4
                                              : clockW.visible ? clockW.y + clockW.height + Theme.space4 : widgets.firstY)
        Column {
            width: parent.width
            spacing: Theme.space2
            Label { text: qsTr("NOTE RAPIDE"); level: Label.Tertiary; font.pixelSize: Theme.fsXs; font.weight: Font.DemiBold; font.letterSpacing: 0.5 }
            TextEdit {
                id: note
                width: parent.width
                height: Math.max(90, contentHeight)
                wrapMode: TextEdit.Wrap
                color: Theme.text
                selectionColor: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsMd
                text: Preferences.value("widgets/note/text", "")
                onTextChanged: saveTimer.restart()
                Timer { id: saveTimer; interval: 600; onTriggered: Preferences.setValue("widgets/note/text", note.text) }
                Label { visible: note.text === "" && !note.activeFocus; text: qsTr("Écrire une note…"); level: Label.Tertiary }
            }
        }
    }
}
