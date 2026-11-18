# ADR 0033 — Accessibilité

- **Statut** : accepté
- **Date** : 2026-11-18

## Décision

Paramètres → Accessibilité, en trois groupes :

- **Voir** : taille du texte (existant) ; **contraste élevé** (`Theme.highContrast`, couleurs de
  `[themed_high_contrast]` dans `tokens.toml` : textes, bordures et fonds plus marqués) ; **loupe**
  (effet « zoom » de KWin, Méta + = / Méta + −) ; **taille du pointeur** (24, 36, 48 px, `kcminputrc`,
  prise en compte à la session suivante).
- **Entendre** : **lecteur d'écran Orca** (démarré tout de suite et à chaque session par
  `~/.config/autostart/orca.desktop`), bouton d'installation s'il manque ; `orca` recommandé.
- **Bouger** : réduire les animations (existant).

## Conséquences

- Le contraste élevé s'applique aux applications VinX, pas aux applications tierces.
- Non vérifié ici : loupe, pointeur et Orca demandent une vraie session KWin.
