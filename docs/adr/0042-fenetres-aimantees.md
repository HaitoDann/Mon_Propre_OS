# ADR 0042 — Fenêtres aimantées : aperçu VinX

- **Statut** : accepté
- **Date** : 2026-11-20

## Contexte

KWin sait déjà aimanter les fenêtres, et la session VinX l'active (`shell/session/xdg/kwinrc`) :
- glisser une fenêtre contre le bord gauche ou droit la place en moitié d'écran ;
- contre un coin, en quart ;
- contre le haut, elle s'agrandit ;
- Méta+flèches fait de même au clavier.

L'aperçu affiché pendant le glissement est celui de Plasma (cadre translucide Breeze), hors charte.

## Décision

- `vinx-window-theme`, qui génère déjà la décoration « pastilles » à chaque changement d'accent ou de
  thème (ADR 0024), écrit aussi `~/.local/share/kwin/outline/plasma/outline.qml` (et
  `kwin-wayland/…` pour Plasma 6.4 et suivants). KWin le préfère à celui de Plasma.
- Cet aperçu est une zone arrondie (rayon 14, marge 8) remplie de l'accent à 18 % (22 % en sombre) avec un
  contour de 2 px à l'accent. Elle part de la fenêtre et glisse vers sa place en 200 ms (OutCubic).
- QtQuick uniquement, sans Kirigami ni KSvg : aucune dépendance supplémentaire chargée dans KWin.
- Test `snap-outline` : le QML se charge avec un faux objet `outline` (interface de KWin) et suit la cible.

## Conséquences

- Le fichier vit dans le dossier de l'utilisateur : la session Plasma, si elle est choisie, montre aussi
  l'aperçu VinX.
- Un menu de dispositions au survol du bouton agrandir n'est pas possible avec une décoration Aurorae ;
  il est écarté pour l'instant.
- À vérifier sur le portable : l'emplacement exact cherché par la version de KWin de Debian 13.
