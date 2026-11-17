# ADR 0024 — Fenêtres VinX : boutons « pastilles » à droite

- **Statut** : accepté
- **Date** : 2026-11-17

## Contexte

Les fenêtres utilisaient la décoration Breeze de KDE (boutons à gauche). Maquettes de quatre styles ;
choix de l'utilisateur : **A « Pastilles »**, **en haut à droite comme sous Windows**.

## Décision

- Décoration **Aurorae** de KWin (thème SVG, aucune extension C++ de KWin à maintenir), nommée
  « VinX ». Les fichiers sont **générés** par `vinx-window-theme` (`shell/windowtheme`, analyse pure
  dans `auroraetheme.h`, testée) :
  - pastilles de 14 px dans des boutons de 26 px ; ordre réduire, agrandir, fermer (`ButtonsOnRight=IAX`) ;
  - fermeture à la couleur d'accent sur la fenêtre active, rouge `#E5484D` au survol ; pictogrammes
    au survol ; fenêtre inactive neutre ;
  - barre de 40 px, titre centré, coins supérieurs arrondis, contour d'un pixel ; fenêtre agrandie
    sans contour.
- Un thème par défaut (clair, vert) est installé dans `/usr/share/aurorae/themes/VinX`. Le shell
  écrit celui de l'utilisateur (`~/.local/share/aurorae/themes/VinX`, prioritaire) à chaque
  changement d'accent ou de thème, puis demande à KWin de se reconfigurer (D-Bus).
- `vinx-session` impose la décoration pour la durée de la session VinX (la configuration de
  l'utilisateur écrite par Plasma passerait sinon avant) et la retire en sortie.

## Conséquences

- Ombre des fenêtres : celle de KWin pour Aurorae (pas d'ombre dessinée par le thème pour l'instant).
- Le paquet Debian fournissant Aurorae est en `Recommends` (nom à confirmer par la CI) ; sans lui,
  KWin revient à Breeze.
- Vérifiable seulement en session KWin réelle.
