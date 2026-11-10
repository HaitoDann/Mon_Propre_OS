# Règles de design de VinX OS

Ces règles s'appliquent à toute interface de VinX OS : shell, applications système, maquette.
Elles traduisent les recommandations des grands systèmes de design (Apple HIG, Microsoft Fluent 2,
GNOME HIG) et des critères d'accessibilité WCAG. Les valeurs sont dans [`branding/tokens.toml`](../branding/tokens.toml).

## 1. Couleur : une base neutre, un accent rare

| Règle | Application |
|---|---|
| **Base neutre** pour 90 % de la surface : fonds, fenêtres, barres, menus. | Gris légèrement froids (`#141517` → `#232427` en sombre). Jamais de fond teinté de couleur. |
| **Un seul accent**, sobre, réservé à : action principale, état actif (interrupteur, tuile), sélection, focus clavier. | Indigo désaturé `#5B65C9` (clair : `#4E58BE`). Pas de dégradé d'accent. |
| **Pas de noir pur** en thème sombre (éblouissement, halo autour du texte). | Fond `#141517`, texte `#ECECEE`. |
| **Profondeur par la luminosité**, pas par la couleur : plus une surface est élevée, plus elle est claire (sombre) ou blanche et ombrée (clair). | Fond < fenêtre < menu/panneau. |
| **Couleurs d'état** réservées à leur sens (succès, alerte, danger), désaturées. | `#3FA66B`, `#D4A13C`, `#E5484D`. |
| **La couleur de marque reste au logo.** | Le violet `#A855F7` n'apparaît que dans le logo, l'écran de démarrage et l'installateur. |

## 2. Contraste (WCAG 2.2 AA)

- Texte courant : **≥ 4,5:1** ; grand texte (≥ 18 px, ou 14 px gras) : **≥ 3:1**.
- Composants et icônes porteurs d'information (bordure de champ, interrupteur, icône d'état) : **≥ 3:1**.
- Valeurs vérifiées pour la palette actuelle (sombre / clair) :

| Paire | Sombre | Clair |
|---|---|---|
| Texte principal / fond | 15,5:1 | 15,5:1 |
| Texte secondaire / fenêtre | 6,6:1 | 5,3:1 |
| Texte tertiaire (indications) / fenêtre | 3,8:1 | 3,3:1 |
| Texte blanc / bouton d'accent | 5,1:1 | 6,1:1 |
| Accent (texte, focus) / fond | 5,5:1 | 6,1:1 |

## 3. Hiérarchie et typographie

- **Une police** (Inter), hiérarchie par **taille et graisse**, pas par la couleur.
- Échelle courte : 11 / 12 / 13 (corps) / 15 / 20 / 56 px.
- Trois niveaux de texte seulement : principal, secondaire, tertiaire.
- Titres de section en petites capitales espacées, couleur secondaire.

## 4. Formes, espacements, mouvement

- Grille de **4 px** (4, 8, 12, 16, 24, 32).
- Rayons modestes et cohérents : 5–7 px (contrôles), 10–12 px (cartes, fenêtres), 16 px (dock).
- Bordures fines (1 px, blanc ou noir à 7–12 %) plutôt qu'ombres marquées ; ombres douces.
- Animations **courtes** (120–320 ms), décélérées, jamais décoratives ; respect du réglage « réduire les animations ».

## 5. Ergonomie bureautique

- **Densité confortable** : cibles cliquables ≥ 24 px (barre), ≥ 28 px (contrôles), ≥ 44 px (tactile).
- **Tout au clavier** : ordre de tabulation logique, focus toujours visible (anneau d'accent 2 px),
  raccourcis affichés dans les menus, `Échap` ferme l'élément le plus haut.
- **Prévisibilité** : un même geste produit le même effet partout ; pas de mode caché.
- **Calme visuel** : rien ne clignote ni ne bouge sans action de l'utilisateur ; notifications discrètes,
  regroupées, désactivables (Ne pas déranger).
- **Lisibilité des états** : un état ne repose jamais sur la seule couleur (icône ou texte en plus).
- **Icônes** : un seul style au trait, grille 24 px ; icônes d'applications en teintes unies désaturées
  de luminosité proche, pour un dock homogène.

## Sources

- Apple — Human Interface Guidelines, [Color](https://developer.apple.com/design/human-interface-guidelines/color.md) et [Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode.md)
- Microsoft — [Fluent 2, Color](https://fluent2.microsoft.design/color) ; [Office Add-ins, color guidelines](https://learn.microsoft.com/en-us/office/dev/add-ins/design/add-in-color)
- GNOME — [Human Interface Guidelines](https://developer.gnome.org/hig) et [UI Styling](https://developer.gnome.org/hig/guidelines/ui-styling.html)
- Accessibilité et thème sombre : [Uxcel — Dark Mode Design](https://uxcel.com/blog/12-principles-of-dark-mode-design-627), [LogRocket — Dark mode UI best practices](https://blog.logrocket.com/ux-design/dark-mode-ui-design-best-practices-and-examples/), [Accessibility Checker — Dark Mode Accessibility](https://www.accessibilitychecker.org/blog/dark-mode-accessibility/)
