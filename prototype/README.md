# Maquette interactive du Desktop Shell VinX OS

Référence visuelle et comportementale du futur shell natif (Qt 6 / QML + KWin).
HTML, CSS et JavaScript purs, sans dépendance ni build.

**Lancer :** ouvrir `index.html` dans un navigateur récent (Chrome, Firefox, Edge, Safari).
Les préférences (thème, fond d'écran, widgets, dock) sont mémorisées dans le navigateur ;
*Paramètres → Maquette → Réinitialiser* les remet à zéro.

## Fonctionnalités

| Zone | Ce qui fonctionne |
|---|---|
| Barre supérieure | Menu système (logo), menus d'application, indicateur d'espaces, recherche, centre de contrôle, calendrier + notifications |
| Dock | Agrandissement, indicateurs, infobulles, épinglées / ouvertes, menu contextuel, réduction animée vers l'icône |
| Bureau | Fond d'écran (2 variantes), widgets Horloge / Agenda / Note déplaçables, menu contextuel |
| Espaces de travail | 3 bureaux (jusqu'à 6), changement animé, déplacement de fenêtres |
| Vue d'ensemble | Mosaïque des fenêtres, vignettes des bureaux, glisser une fenêtre vers un autre bureau |
| Recherche globale | Applications, actions, réglages, fichiers, calcul, web — navigation au clavier |
| Fenêtres | Déplacement, redimensionnement par bords/coins, agrandir, plein écran, réduire, magnétisme (moitiés, quarts, haut = agrandir), organisation automatique, menu de fenêtre |
| Design system | Tokens centralisés, thèmes sombre et clair, couleur d'accent |

## Raccourcis clavier

| Raccourci | Action |
|---|---|
| `Ctrl + Espace` | Recherche globale |
| `F3` ou `Ctrl + Alt + ↑` | Vue d'ensemble |
| `Ctrl + Alt + ← / →` | Espace de travail précédent / suivant |
| `Ctrl + Alt + Maj + ← / →` | Déplacer la fenêtre vers l'espace voisin |
| `Ctrl + Maj + ← / →` | Placer la fenêtre à gauche / à droite |
| `Ctrl + Maj + ↑` | Agrandir / restaurer |
| `Ctrl + Maj + ↓` | Réduire |
| `Ctrl + Maj + F` | Plein écran |
| `Ctrl + Maj + G` | Organiser les fenêtres |
| `Ctrl + W` | Fermer la fenêtre |
| `Échap` | Fermer un panneau, quitter le plein écran ou la vue d'ensemble |

Dans l'OS final, `Ctrl` sera remplacé par la touche `Super` pour les actions système.

## Architecture

Chaque fichier correspond à un futur composant QML — voir [`docs/UX.md`](../docs/UX.md).

```
css/tokens.css     Design tokens (→ Theme.qml)         js/core.js      État + événements (→ ShellState)
css/base.css       Primitives (bouton, verre, icône)   js/icons.js     Icônes SVG + logo
css/desktop.css    Bureau, widgets, OSD                js/apps.js      Registre des apps, raccourcis
css/topbar.css     Barre supérieure                    js/wm.js        Fenêtres, tuiles, espaces (→ KWin)
css/popover.css    Menus et panneaux                   js/expose.js    Vue d'ensemble
css/dock.css       Dock                                js/desktop.js   Widgets, menu du bureau
css/window.css     Fenêtres, magnétisme, Paramètres    js/dock.js      Dock
css/expose.css     Vue d'ensemble                      js/topbar.js    Barre, centre de contrôle, calendrier
css/search.css     Recherche globale                   js/search.js    Recherche globale
                                                       js/main.js      Raccourcis, démarrage
```
