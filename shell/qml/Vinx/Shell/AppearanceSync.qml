import QtQuick
import Vinx.Theme
import Vinx.System

// Applique les préférences partagées (apparence, Ne pas déranger) (Paramètres, barre, recherche).
// À placer une fois par processus (shell, applications VinX).
QtObject {
    // Shell uniquement : écrit le thème de fenêtre VinX (accent, clair/sombre) et recharge KWin.
    property bool windowTheme: false
    // Shell uniquement : l'accent suit la couleur de l'espace courant (ADR 0044). La décoration des
    // fenêtres et l'écran de connexion gardent l'accent global (pas de rechargement de KWin à chaque
    // changement d'espace).
    property bool spaces: false
    function truthy(v, fallback) { return v === undefined || v === null ? fallback : v === true || v === "true" }
    function apply() {
        Theme.dark = truthy(Preferences.value("appearance/dark"), false)   // thème clair par défaut
        const globalAccent = resolveAccent(String(Preferences.value("appearance/accent", "")))
        const spaceAccent = spaces && Tasks.backend ? ShellState.spaceColorAt(Tasks.backend.currentDesktopIndex) : ""
        Theme.accentId = spaceAccent || globalAccent
        if (spaces) ShellState.spaceTinted = spaceAccent !== ""
        const g = Theme.accents.find(a => a.id === globalAccent) || Theme.accents[0]
        Theme.reduceMotion = truthy(Preferences.value("accessibility/reduceMotion"), false)
        Theme.highContrast = truthy(Preferences.value("accessibility/highContrast"), false)
        Theme.shapeStyle = String(Preferences.value("appearance/shape", "soft"))
        Theme.textScale = Number(Preferences.value("accessibility/textScale", 1.0)) || 1.0
        // Accent résolu (« auto » compris) pour les applications C++ (Terminal VinX).
        if (windowTheme && String(Preferences.value("appearance/resolvedAccent", "")) !== globalAccent)
            Preferences.setValue("appearance/resolvedAccent", globalAccent)
        if (windowTheme)
            ShellState.syncWindowTheme(String(g.fill), String(g.ink), Theme.dark)
        if (windowTheme)
            ShellState.syncGreeter(Theme.dark, globalAccent)
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
    property int _desktop: spaces && Tasks.backend ? Tasks.backend.currentDesktopIndex : -1
    on_DesktopChanged: if (spaces) apply()
    property var _ids: spaces && Tasks.backend ? Tasks.backend.desktopIds : []
    on_IdsChanged: if (spaces) apply()
    property int revision: Preferences.revision
    onRevisionChanged: apply()
    Component.onCompleted: apply()
}
