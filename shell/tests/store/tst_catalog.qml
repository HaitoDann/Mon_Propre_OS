import QtQuick
import QtTest
import "../../apps/store/Catalog.js" as Catalog

TestCase {
    name: "StoreCatalog"

    function test_categories_are_well_formed() {
        verify(Catalog.categories.length >= 6)
        const seen = {}
        for (const c of Catalog.categories) {
            verify(c.id && c.name && /^#[0-9A-F]{6}$/i.test(c.tint), c.id)
            verify(c.apps.length > 0, c.id)
            for (const a of c.apps) {
                verify(a.pkg || a.flatpak, "ni paquet ni Flathub : " + a.name)
                verify(a.name && a.summary, "nom ou résumé manquant : " + (a.pkg || a.flatpak))
                if (a.flatpak) verify(/^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+){2,}$/.test(a.flatpak), "identifiant Flathub invalide : " + a.flatpak)
                if (a.pkg) verify(/^[a-z0-9][a-z0-9.+-]+$/.test(a.pkg), "nom de paquet invalide : " + a.pkg)
                const key = a.pkg || a.flatpak
                verify(!seen[key], "logiciel en double : " + key)
                seen[key] = true
            }
        }
    }
    function test_selection_and_popular_exist_in_catalog() {
        for (const s of Catalog.selection) {
            verify(Catalog.find(s.pkg) !== null, s.pkg)
            verify(s.tagline.length > 10)
        }
        for (const p of Catalog.popular) verify(Catalog.find(p) !== null, p)
    }
    function test_helpers() {
        compare(Catalog.find("gimp").category, "graphics")
        compare(Catalog.find("com.spotify.Client").name, "Spotify")
        verify(Catalog.packages().indexOf("vlc") >= 0)
        compare(Catalog.category("office").name, "Bureautique")
    }
}
