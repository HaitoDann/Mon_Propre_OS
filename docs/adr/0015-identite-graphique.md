# ADR 0015 — Identité graphique « OS minimal »

- **Statut** : accepté
- **Date** : 2026-11-15

## Choix de l'utilisateur

| Question | Réponse |
|---|---|
| Ambiance | **Calme et précis** (outil de bureau, beaucoup d'espace) |
| Style d'icônes | **Pictogramme blanc au trait sur une forme colorée** |
| Forme des icônes | **Forme libre** (silhouette de l'objet) |
| Accent | **Violet du logo atténué** |

## Décision

- **Icônes** : silhouette de l'objet (dossier, page à coin plié, enveloppe, globe/cercle, fenêtre,
  sac, disque, corbeille), teinte unie désaturée, pictogramme VinX blanc au trait, une ombre douce.
  Même dessin pour le dock (`AppIcon.qml`) et pour le thème d'icônes système « VinX »
  (`branding/icon-theme/gen_icons.py`, hérite de Breeze pour les icônes non couvertes).
- **Accent** : `#7358BD` (sombre) / `#6548AE` (clair), texte d'accent `#A58FE0` en sombre ;
  contraste blanc sur accent 5,4:1 et 6,8:1 (WCAG AA).
- **Barre supérieure** : un indicateur n'apparaît que s'il informe (Wi-Fi, réseau coupé,
  son coupé, Ne pas déranger, batterie ; pourcentage sous 20 %). Date masquable.
- **Dock** : masquage automatique optionnel (zone réservée libérée, réapparition au bord bas).
- **Fenêtres** : Breeze réglé (sans bordure, barre de titre sans séparateur, petits boutons,
  titre centré, ombre moyenne).
- **Thème unifié** : thème d'icônes VinX, police Inter, palette VinX pour Qt (schémas de couleurs)
  et GTK (Breeze-GTK synchronisé par kde-config-gtk-style).

## Conséquences

- Les silhouettes existent en deux endroits (`AppIcon.qml`, `gen_icons.py`) : à modifier ensemble.
- Ajouter une application connue = une ligne dans `gen_icons.py` (et `AppStyle.js` pour le dock).

## Révision — direction « Biseau » (2026-11-15)

Trois maquettes (Biseau, Îlot, Ligne) ont été présentées ; l'utilisateur a retenu **Biseau** :

- **Signature** : coins haut-droit et bas-gauche coupés en biseau (angle du logo V/X), via le
  composant `Bevel` : surfaces, menus, panneaux, notifications, boutons, tuiles, plateau du dock,
  widgets. Les icônes rondes deviennent des tuiles biseautées ; les silhouettes (dossier, page,
  enveloppe…) sont conservées.
- **Fond** : sombre neutre technique, grille discrète et deux bandes violettes en V
  (`vinx-biseau.svg`, fond par défaut « VinX Biseau »).
- **Dock** : en bas par défaut (comme macOS), à gauche en option (Paramètres → Dock → Position) ;
  l'agrandissement au survol n'existe qu'en bas.

## Révision — formes douces (2026-11-16)

Après comparaison sur captures, l'utilisateur préfère des **formes douces** : coins arrondis
partout (`Theme.shapeStyle = "soft"`, par défaut), tuiles d'icônes arrondies. Le biseau devient
une **signature rare** : logo, fond d'écran, trait d'accent animé à l'ouverture des panneaux.
Le style « bevel » reste disponible (préférence `appearance/shape`).
