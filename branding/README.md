# Branding

Tout le visuel est défini ici. Identité en vigueur : **vert du logo `#10DD8C`, thème clair,
IBM Plex Sans** (règles : [docs/DESIGN.md](../docs/DESIGN.md), décision : ADR 0018).
Pour changer les couleurs de l'interface, on modifie `tokens.toml` : `Theme.qml` est régénéré à la construction.

## Fichiers

| Fichier | Rôle |
|---|---|
| `brand.toml` | Nom, couleurs principales, chemins des logos (version : paquet vinx-shell, ADR 0040) |
| `tokens.toml` | Design tokens complets (couleurs par thème, typo, espacements, rayons, durées) → `Theme.qml` |
| `icons/` | Pictogrammes SVG de l'interface (trait 1,8 px, grille 24 px) |
| `icon-theme/gen_icons.py` | Générateur du thème d'icônes système « VinX » (tuile + pictogramme + point) |
| `logo/` | Logo vert (`vinx-logo.svg`) et variantes |
| `wallpaper/` | Fonds d'écran ; défaut `vinx-logo-clair.svg` (et `-sombre`) ; anciens fonds gardés en option |
| `boot/` | GRUB / isolinux (`splash-*.svg`), Plymouth (`plymouth-*.svg`) |
| `fonts/ibm-plex-sans/` | Police système (OFL), installée par `vinx-shell` |
