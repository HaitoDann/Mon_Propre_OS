import QtQuick
import Vinx.Theme

// Surface des bulles de notification (layer-shell, en haut à droite, sans zone réservée).
Window {
    width: 360 + Theme.space2
    height: Math.max(1, toasts.height + Theme.space2)
    color: "transparent"
    visible: false
    title: "vinx-notifications"
    Toasts { id: toasts; x: 0; y: Theme.space2 }
}
