import QtQuick
import Vinx.Theme
import Vinx.System

// Applique les préférences partagées (apparence, Ne pas déranger) (Paramètres, barre, recherche).
// À placer une fois par processus (shell, applications VinX).
QtObject {
    function truthy(v, fallback) { return v === undefined || v === null ? fallback : v === true || v === "true" }
    function apply() {
        Theme.dark = truthy(Preferences.value("appearance/dark"), false)   // thème clair par défaut
        Theme.accentId = resolveAccent(String(Preferences.value("appearance/accent", "")))
        Theme.reduceMotion = truthy(Preferences.value("accessibility/reduceMotion"), false)
        Theme.shapeStyle = String(Preferences.value("appearance/shape", "soft"))
        Theme.textScale = Number(Preferences.value("accessibility/textScale", 1.0)) || 1.0
        Notifications.doNotDisturb = truthy(Preferences.value("notifications/dnd"), false)
    }
    // Accent : identifiant du nuancier, « auto » (d'après le fond d'écran) ou vide/inconnu (défaut).
    property string _autoPath: ""
    property string _autoId: ""
    function resolveAccent(pref) {
        if (pref !== "auto")
            return Theme.accents.some(a => a.id === pref) ? pref : Theme.accents[0].id
        const path = String(Preferences.value("desktop/wallpaper", ""))
        // « VinX Logo » prend lui-même la couleur d'accent : on garde le vert.
        if (path === "" || /\/VinX-Logo(-Sombre)?\//.test(path))
            return Theme.accents[0].id
        if (path !== _autoPath) {
            _autoPath = path
            _autoId = Session.pickAccent(path, Theme.accents, "graphite")
        }
        return _autoId
    }
    property int revision: Preferences.revision
    onRevisionChanged: apply()
    Component.onCompleted: apply()
}
