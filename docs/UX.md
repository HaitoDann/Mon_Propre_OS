# Guide UX du Desktop Shell

Règles d'expérience du bureau, issues de la maquette (`prototype/`, ancienne charte violette,
conservée pour mémoire) et appliquées dans le shell Qt 6 / QML (`shell/`). Pour le visuel, la
référence est [DESIGN.md](DESIGN.md).

## Principes

1. **Chaque élément a une utilité.** Rien de décoratif sans fonction.
2. **Le bureau reste calme.** Widgets optionnels et désactivables, notifications discrètes, animations courtes (120–360 ms).
3. **Tout est accessible au clavier** et à la souris ; chaque action de menu affiche son raccourci.
4. **Une seule source de style** : les tokens de `branding/tokens.toml`. Aucun composant ne code de couleur en dur.
5. **Clair et sombre** sont deux thèmes de premier rang ; le **clair** est le défaut (ADR 0018).

## Composants et correspondance native

| Maquette | Implémentation cible | Notes |
|---|---|---|
| `tokens.css` | `Theme.qml` (singleton) généré depuis `brand.toml` | Couleurs, typo, espacements, rayons, ombres, durées |
| Barre supérieure | `TopBar.qml` (panneau layer-shell) | 34 px, verre flouté ; menus d'app via D-Bus (protocole de menus global) |
| Centre de contrôle | `ControlCenter.qml` | NetworkManager, BlueZ, PipeWire, UPower, luminosité via D-Bus |
| Calendrier / notifications | `NotificationCenter.qml` | Serveur `org.freedesktop.Notifications` implémenté par le shell |
| Dock | `Dock.qml` (layer-shell) | Liste des fenêtres via l'API KWin ; épinglage dans la config utilisateur |
| Recherche globale | `Search.qml` + service de recherche | Sources en plugins : apps (.desktop), fichiers (index), réglages, calcul, web |
| Fenêtres, magnétisme, tuiles | **KWin** (script + effets) | Zones : moitiés, quarts, agrandi ; marge 8 px ; décorations à la charte |
| Espaces de travail | **KWin** (bureaux virtuels) | 3 par défaut, 6 max, OSD au changement |
| Vue d'ensemble | Effet KWin *Overview* thémé | Glisser une fenêtre vers une vignette = changer d'espace |
| Widgets | `Desktop.qml` + widgets QML enfichables | Horloge, Agenda, Note ; position libre mémorisée |
| Paramètres | Application `apps/settings` | Apparence, fond d'écran, bureau, dock |

## Comportements clés

- **Clic sur une icône du dock** : lance l'app ; avec une seule fenêtre, la ramène (même réduite) ou la réduit si elle est au premier plan ; avec plusieurs fenêtres, ouvre la **liste de ses fenêtres** (les réduites sont marquées « Réduite »).
- **Points sous les icônes** : un par fenêtre (trois au plus) ; **plein = visible, creux = réduite**.
- **Toutes les fenêtres** : bouton en grille dans la barre (à droite) ou **Méta+W** → vue d'ensemble de KWin, fenêtres réduites comprises. (Méta seule reste la recherche.)
- **Glisser une fenêtre** contre un bord : moitié d'écran ; contre un coin : quart ; vers le haut : agrandie. Un aperçu translucide à la couleur d'accent montre la zone avant de relâcher.
- **Glisser une fenêtre en tuile** : elle retrouve sa taille d'origine sous le pointeur.
- **Bouton vert** : plein écran (la barre et le dock s'effacent, `Échap` pour sortir). **Double-clic sur la barre de titre** : agrandir.
- **Clic droit** : sur la barre de titre → menu de fenêtre ; sur le bureau → widgets et organisation ; sur le dock → fenêtres et épinglage.
- **Outils du quotidien** : **Ctrl+Échap** moniteur système (ADR 0035) ; **Méta+Maj+S** capture d'une zone, d'une fenêtre ou d'un écran avec annotation, **Impr. écran** capture de tout l'écran (ADR 0036) ; **Méta+V** historique du presse-papiers (ADR 0037). Les images s'ouvrent dans **Images** (ADR 0038). Toute capture est copiée aussitôt.
- **Échap** ferme toujours l'élément le plus haut : menu, recherche, vue d'ensemble, puis plein écran.

Raccourcis : voir [`prototype/README.md`](../prototype/README.md).
