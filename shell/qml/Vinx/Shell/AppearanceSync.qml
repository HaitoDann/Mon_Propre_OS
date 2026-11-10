import QtQuick
import Vinx.Theme
import Vinx.System

// Applique les préférences partagées (apparence, Ne pas déranger) (Paramètres, barre, recherche).
// À placer une fois par processus (shell, applications VinX).
QtObject {
    function truthy(v, fallback) { return v === undefined || v === null ? fallback : v === true || v === "true" }
    function apply() {
        Theme.dark = truthy(Preferences.value("appearance/dark"), true)
        const accent = Preferences.value("appearance/accent", "")
        Theme.accentOverride = accent ? accent : "transparent"
        Notifications.doNotDisturb = truthy(Preferences.value("notifications/dnd"), false)
    }
    property int revision: Preferences.revision
    onRevisionChanged: apply()
    Component.onCompleted: apply()
}
