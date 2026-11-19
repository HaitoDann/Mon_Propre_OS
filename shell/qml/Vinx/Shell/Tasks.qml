pragma Singleton
import QtQuick
import Vinx.System

// Fournisseur de tâches (applications épinglées + fenêtres ouvertes) partagé par le dock et la barre.
// En session réelle : gestionnaire de tâches de KDE (fenêtres de KWin). Sinon : modèle d'aperçu.
QtObject {
    id: tasks
    readonly property var backend: _create()
    readonly property bool live: backend ? backend.live : false

    function _create() {
        // VINX_TASKS_BACKEND=preview impose le modèle d'aperçu (tests, même si Plasma est installé).
        // Hors Wayland (captures hors écran, X11) : libtaskmanager plante dans VirtualDesktopInfo
        // faute de connexion Wayland ; on prend aussi le modèle d'aperçu.
        if (Session.environment("VINX_TASKS_BACKEND") === "preview" || Qt.platform.pluginName !== "wayland")
            return Qt.createComponent("PreviewTasksBackend.qml").createObject(tasks)
        const kde = Qt.createComponent("KdeTasksBackend.qml")
        if (kde.status === Component.Ready) {
            const o = kde.createObject(tasks)
            if (o) return o
        }
        console.info("vinx-shell : gestionnaire de tâches KDE indisponible (" + kde.errorString().trim() + ") — mode aperçu")
        return Qt.createComponent("PreviewTasksBackend.qml").createObject(tasks)
    }
}
