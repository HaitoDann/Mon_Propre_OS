# ADR 0008 — Organisation du shell et du design system QML

- **Statut** : accepté
- **Date** : 2026-11-10

## Contexte
Le shell natif (phase 3) et les applications système doivent partager un même style et les mêmes
composants, fidèles à la maquette, tout en restant personnalisables depuis `branding/`.

## Décision
- **Source unique des tokens** : `branding/tokens.toml`. `Theme.qml` en est **généré** à la compilation
  (`shell/tools/gen_theme.py`) ; il n'est jamais modifié à la main.
- **Icônes** : SVG au trait dans `branding/icons/`, embarqués dans `Vinx.Controls` et recolorés par un
  composant C++ `Icon` (`QQuickPaintedItem` + `QSvgRenderer`), sans module d'effets graphiques.
- **Modules** : `Vinx.Theme` et `Vinx.Controls`, plugins QML partagés installés dans le dossier QML de Qt,
  réutilisables par `vinx-shell`, Paramètres et Store.
- **Composants maison** sur QtQuick (sans Qt Quick Controls) pour une maîtrise totale du rendu.
- **Flou** délégué à KWin (effet *blur* sur les surfaces du shell) ; ombres dessinées en QML.
- **Compatibilité** Qt ≥ 6.4 ; tests Qt Quick Test exécutés à chaque construction du paquet.

## Conséquences
Changer une couleur ou une icône dans `branding/` met à jour toute l'interface à la compilation suivante.
`prototype/css/tokens.css` reste pour l'instant une copie manuelle des mêmes valeurs ; sa génération
depuis `tokens.toml` est à faire. La licence du projet reste à choisir (champ `TODO` dans `debian/copyright`).
