import QtQuick
import QtTest
import "../../apps/store/Catalog.js" as Catalog

TestCase {
    name: "StoreCatalog"

    function test_packs_are_well_formed() {
        verify(Catalog.packs.length >= 5)
        const seen = {}
        for (const p of Catalog.packs) {
            verify(p.id && p.name && p.summary && p.glyph && p.tint, p.id)
            verify(p.apps.length > 0, p.id)
            for (const a of p.apps) {
                verify(/^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+){2,}$/.test(a.id), "identifiant Flathub invalide : " + a.id)
                verify(!seen[a.id], "application en double : " + a.id)
                seen[a.id] = true
            }
        }
    }
    function test_ids_helper() {
        compare(Catalog.ids(Catalog.packs[0]).length, Catalog.packs[0].apps.length)
    }
}
