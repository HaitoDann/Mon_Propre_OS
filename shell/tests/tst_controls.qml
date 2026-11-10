import QtQuick
import QtTest
import Vinx.Theme
import Vinx.Controls

Item {
    id: root
    width: 600; height: 400

    Switch { id: sw; x: 10; y: 10 }
    Slider { id: slider; x: 10; y: 50; width: 200 }
    SegmentedControl { id: seg; x: 10; y: 90; model: ["A", "B", "C"] }
    Button { id: btn; x: 10; y: 130; text: "OK"; property int count: 0; onClicked: count++ }
    Icon { id: icon; name: "wifi" }
    Item {
        anchors.fill: parent
        Button { id: anchorBtn; x: 300; y: 10; text: "Menu" }
        Menu {
            id: menu
            model: [{ text: "Premier" }, { separator: true }, { text: "Second" }]
            property var last
            onTriggered: (i, entry) => last = entry.text
        }
    }

    TestCase {
        name: "VinxControls"
        when: windowShown

        function test_switch_click_and_keyboard() {
            compare(sw.checked, false)
            mouseClick(sw)
            compare(sw.checked, true)
            keyClick(Qt.Key_Space)
            compare(sw.checked, false)
        }

        function test_slider_clamps_and_steps() {
            slider.setValue(5)
            compare(slider.value, 1)
            slider.setValue(-1)
            compare(slider.value, 0)
            slider.forceActiveFocus()
            keyClick(Qt.Key_Right)
            fuzzyCompare(slider.value, 0.05, 1e-9)
            mouseClick(slider, slider.width - 1, slider.height / 2)
            compare(slider.value, 1)
        }

        function test_segmented_selection() {
            compare(seg.currentIndex, 0)
            mouseClick(seg, seg.width - 5, seg.height / 2)
            compare(seg.currentIndex, 2)
            keyClick(Qt.Key_Left)
            compare(seg.currentIndex, 1)
        }

        function test_button_click_and_keyboard() {
            mouseClick(btn)
            compare(btn.count, 1)
            keyClick(Qt.Key_Return)
            compare(btn.count, 2)
            btn.enabled = false
            mouseClick(btn)
            compare(btn.count, 2)
            btn.enabled = true
        }

        function test_icon_loads_from_resources() {
            verify(icon.valid)
            icon.name = "nexiste-pas"
            verify(!icon.valid)
        }

        function test_theme_switch() {
            Theme.dark = true
            const darkWindow = Theme.surfaceWindow.toString()   // copie (les couleurs sont des références)
            Theme.dark = false
            verify(darkWindow !== Theme.surfaceWindow.toString())
            compare(Theme.accent, Qt.color("#7C3AED"))
            Theme.accentOverride = "#EC4899"
            compare(Theme.accent, Qt.color("#EC4899"))
            Theme.accentOverride = "transparent"
            Theme.dark = true
            compare(Theme.accent, Qt.color("#A855F7"))
        }

        function test_menu_opens_triggers_and_closes() {
            menu.show(anchorBtn)
            verify(menu.open)
            tryCompare(menu, "visible", true)
            // Clic sur la première entrée
            const first = menu.mapFromItem(anchorBtn, 20, anchorBtn.height + 6 + 4 + 13)
            mouseClick(menu, first.x, first.y)
            compare(menu.last, "Premier")
            verify(!menu.open)
            // Clic extérieur
            menu.show(anchorBtn)
            mouseClick(menu, 5, 390)
            verify(!menu.open)
        }
    }
}
