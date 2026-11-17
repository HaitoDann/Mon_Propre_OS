# Règles de design de VinX OS

Identité en vigueur : **design industriel et tech sobre, vert du logo, thème clair** (ADR 0018).
Ces règles s'appliquent à toute interface : shell, applications VinX, écrans de démarrage et de
connexion, installateur. Les valeurs exactes sont dans [`branding/tokens.toml`](../branding/tokens.toml)
(source unique, générée en `Theme.qml`) ; ce document en donne le sens.

## 1. Couleurs

| Rôle | Clair (défaut) | Sombre | Usage |
|---|---|---|---|
| Fond | `#ECEBE6` blanc cassé chaud | `#121413` | Bureau, arrière-plans |
| Surfaces | `#F8F7F4` | `#1A1C1B` / `#1E2120` | Fenêtres, panneaux, menus |
| Encre (texte) | `#141414` | `#ECECEA` | Texte principal |
| Texte secondaire | `#5F5E5A` | `#A3A6A3` | Sous-titres, descriptions |
| Bordures | `#D8D6CF` | blanc 8 % | Séparations, contours |
| **Accent : vert du logo** | `#10DD8C` | `#10DD8C` | Bouton principal, interrupteurs, curseurs, sélection, trait signature |
| Encre sur l'accent | `#06130D` | `#06130D` | Texte posé sur le vert (**jamais de blanc sur le vert**) |
| Vert foncé (texte, focus) | `#0A7F51` | `#10DD8C` | Liens, texte vert, anneau de focus, bord des contrôles actifs |
| États | succès `#3FA66B` · alerte `#D4A13C` · danger `#E5484D` | idem | Uniquement pour leur sens |

Règles :
- **Un seul accent, le vert du logo**, utilisé avec parcimonie. Jamais de dégradé.
- **Le logo est vert** (`#10DD8C`) partout : barre, démarrage, connexion, installateur, fond d'écran.
- **Thème clair par défaut** ; le sombre est disponible (Paramètres → Apparence).
- Plus aucune trace de l'ancien violet ou de l'indigo (abandonnés, voir ADR 0015 → 0018).

## 2. Contraste (WCAG 2.2 AA)

| Paire | Rapport |
|---|---|
| Encre `#06130D` sur vert `#10DD8C` | 10,6:1 |
| Vert foncé `#0A7F51` sur surface claire | 4,7:1 |
| Vert `#10DD8C` sur surface sombre | 9,6:1 |
| Texte secondaire clair `#5F5E5A` sur surface | 6,1:1 |

Le vert clair sur fond clair n'atteint que 1,7:1 : les interrupteurs et curseurs actifs ont donc
un **bord vert foncé**, et l'état se lit aussi par la position ou le texte (jamais la couleur seule).

## 3. Typographie

- **IBM Plex Sans** pour toute l'interface (fournie avec `vinx-shell`, licence SIL OFL).
- Hiérarchie par **taille et graisse**, pas par la couleur. Échelle : 11 / 12 / 13 (corps) / 15 / 20 / 56 px.
- **Pas d'étiquettes en police technique** (pas de monospace décoratif, pas de petites capitales
  à la machine à écrire). Les titres de section sont en petites capitales espacées, couleur secondaire.

## 4. Formes, espacements, mouvement

- **Formes douces** : coins arrondis partout (`Theme.shapeStyle = "soft"`). Rayons 5–7 px
  (contrôles), 10–12 px (cartes, panneaux), 16 px (dock), 24 % du côté (tuiles d'icônes).
- Le **biseau** (angle coupé du logo) n'est plus une forme d'interface : il ne subsiste que comme
  option cachée (`appearance/shape = bevel`).
- Grille de **4 px** (4, 8, 12, 16, 24, 32). Bordures fines plutôt qu'ombres marquées.
- **Animation signature** : un panneau arrive en glissant le long de la diagonale depuis son coin
  haut-droit, puis un **court trait vert** se dessine sur son bord haut, près du coin.
- Animations courtes (120–320 ms), décélérées ; « Réduire les animations » les supprime.

## 5. Icônes

- **Applications VinX et outils système** : tuile neutre arrondie (`#E3E1DB`, sombre `#2A2D2B`),
  **pictogramme à l'encre au trait**, **un point de couleur** en haut à droite qui identifie l'app.
- **Applications tierces** (Firefox, LibreOffice, Thunderbird…) : **leur logo officiel**, posé sur
  la même tuile neutre pour un dock homogène.
- Dossiers et types de fichiers : même tuile + pictogramme + point (thème d'icônes « VinX »,
  généré par `branding/icon-theme/gen_icons.py`, hérite de Breeze pour le reste).
- Pictogrammes d'interface : jeu `branding/icons/` au trait 1,8 px, grille 24 px.

## 6. Fond d'écran et écrans système

- Fond par défaut **« VinX Logo »** : blanc cassé, grille de points discrète, **logo vert en grand,
  décalé à droite**. Variante « VinX Logo (sombre) ».
- Démarrage (Plymouth), menu GRUB, connexion (SDDM), verrouillage : même fond clair à points,
  logo vert, cartes claires, IBM Plex Sans.

## 7. Ergonomie

- **Densité confortable** : cibles ≥ 24 px (barre), ≥ 28 px (contrôles).
- **Tout au clavier** : ordre de tabulation logique, focus visible (anneau vert foncé 2 px),
  raccourcis affichés dans les menus, `Échap` ferme l'élément le plus haut.
- **Barre minimale** : un indicateur n'apparaît que s'il apporte une information.
- **Calme** : rien ne clignote ni ne bouge sans action de l'utilisateur.
- **Pages natives VinX** pour les réglages courants ; un lien « Avancé… » vers KDE pour les cas rares.

## Historique de l'identité

Gris foncé + violet (abandonné : générique) → biseau partout (abandonné : trop chargé) →
**industriel clair et vert** (en vigueur). Détails : ADR 0015, 0017, 0018.
