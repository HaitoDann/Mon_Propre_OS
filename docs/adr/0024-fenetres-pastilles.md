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
- Pas de paquet « aurorae » séparé dans Debian 13 : le moteur est censé venir avec KWin (à confirmer
  sur le portable) ; s'il manque, KWin revient à Breeze.
- Vérifiable seulement en session KWin réelle.

## Complément (premier essai réel)

Plasma réécrit `library=org.kde.breeze` dans `~/.config/kwinrc` après `vinx-session` : Breeze restait
affiché (seul l'ordre des boutons était pris). `vinx-window-theme --reconfigure`, lancé par le shell
une fois la session démarrée, écrit désormais la décoration VinX (`kwriteconfig6`) avant de
reconfigurer KWin.

## Complément : couleurs des pastilles

Choix de l'utilisateur après le premier essai : pastilles **toujours en couleur** sur la fenêtre
active — réduire orange `#FEBC2E`, agrandir vert `#28C840`, fermer rouge `#FF5F57` —, pictogrammes
(–, +, ×) au survol, grises sur une fenêtre inactive. La fermeture ne suit plus l'accent.

## Complément : applications GTK (Firefox, Thunderbird)

Elles dessinent leur barre de titre (onglets intégrés) et leurs boutons avec GTK, pas avec KWin.
`vinx-window-theme` ajoute aux feuilles `~/.config/gtk-3.0/gtk.css` et `gtk-4.0/gtk.css` un bloc
délimité (remplacé à chaque passage, le reste du fichier — écrit par KDE — est conservé) qui
dessine les boutons en pastilles orange, vert, rouge, grises en arrière-plan.
