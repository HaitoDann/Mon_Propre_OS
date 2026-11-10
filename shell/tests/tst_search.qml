import QtQuick
import QtTest
import Vinx.Shell
import "../qml/Vinx/Shell/Calc.js" as Calc
import "../qml/Vinx/Shell/AppStyle.js" as AppStyle

Item {
    width: 800; height: 600
    Search { id: search }

    TestCase {
        name: "VinxSearch"
        when: windowShown

        function test_app_id_normalization() {
            compare(AppStyle.normalizeId("org.vinx.store", ""), "org.vinx.store")
            compare(AppStyle.normalizeId("org.vinx.store.desktop", ""), "org.vinx.store")
            compare(AppStyle.normalizeId("", "applications:firefox-esr.desktop"), "firefox-esr")
            compare(AppStyle.normalizeId("/usr/share/applications/thunderbird.desktop", ""), "thunderbird")
            compare(AppStyle.normalizeId(undefined, undefined), "")
        }

        function test_calc() {
            compare(Calc.evaluate("2+3*4"), 14)
            compare(Calc.evaluate("(2+3)*4"), 20)
            compare(Calc.evaluate("2^10"), 1024)
            compare(Calc.evaluate("-3 + 5"), 2)
            compare(Calc.evaluate("10 / 4"), 2.5)
            compare(Calc.evaluate("1,5 × 2"), 3)
            compare(Calc.evaluate("17 % 5"), 2)
            compare(Calc.evaluate("0.1+0.2"), 0.3)
        }
        function test_calc_rejects_non_math() {
            compare(Calc.evaluate("firefox"), null)
            compare(Calc.evaluate("42"), null)          // un nombre seul n'est pas un calcul
            compare(Calc.evaluate("2+"), null)
            compare(Calc.evaluate("1/0"), null)
            compare(Calc.evaluate("alert(1)"), null)
        }
        function test_results_have_calc_and_web() {
            search.reset()
            search.apps = [{ id: "org.kde.kcalc", name: "KCalc", genericName: "Calculatrice", keywords: "", icon: "" }]
            keyClick("6"); keyClick("*"); keyClick("7")
            compare(search.items[0].title, "= 42")
            compare(search.items[search.items.length - 1].kind, "Web")
        }
        function test_app_matching_and_ranking() {
            search.reset()
            search.apps = [
                { id: "a", name: "Calendrier", genericName: "", keywords: "", icon: "" },
                { id: "b", name: "Tableur", genericName: "Calcul", keywords: "", icon: "" },
                { id: "c", name: "Calculatrice", genericName: "", keywords: "", icon: "" }
            ]
            keyClick("c"); keyClick("a"); keyClick("l"); keyClick("c")
            const apps = search.items.filter(i => i.kind === "Applications").map(i => i.title)
            compare(apps[0], "Calculatrice")     // préfixe du nom avant le reste
            verify(apps.indexOf("Tableur") > 0)   // correspond via le nom générique
            verify(apps.indexOf("Calendrier") < 0)
        }
        function test_keyboard_selection() {
            search.reset()
            search.apps = [{ id: "a", name: "Alpha", genericName: "", keywords: "", icon: "" },
                           { id: "b", name: "Alphabet", genericName: "", keywords: "", icon: "" }]
            keyClick("a"); keyClick("l")
            compare(search.selected, 0)
            keyClick(Qt.Key_Down)
            compare(search.selected, 1)
            keyClick(Qt.Key_Up)
            compare(search.selected, 0)
        }
    }
}
