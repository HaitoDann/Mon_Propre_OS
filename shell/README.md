# vinx-shell — shell de bureau de VinX OS

Interface native de VinX OS, en **Qt 6 / QML**, au-dessus du compositeur **KWin** ([ADR 0002](../docs/adr/0002-qt6-qml-kwin.md)).
Référence UX : la [maquette](../prototype/) et le [guide UX](../docs/UX.md).

## État

| Étape | Contenu | État |
|---|---|---|
| 1. Socle | CMake, thème généré, paquet `.deb`, CI, galerie | ✅ |
| 2. Design system | `Vinx.Theme`, `Vinx.Controls` | ✅ |
| 3. Barre supérieure | `TopBar.qml` (layer-shell) | à venir |
| 4. Dock | | à venir |
| 5. Session « VinX » | | à venir |

## Architecture

```
branding/tokens.toml ──gen_theme.py──▶ Vinx.Theme (singleton Theme)
branding/icons/*.svg ───────────────▶ Vinx.Controls (ressources, composant Icon)
                                          │
                      vinx-gallery ◀──────┤   (vitrine + recette visuelle)
                      vinx-shell   ◀──────┘   (étape 3+)
```

| Module | Rôle |
|---|---|
| `Vinx.Theme` | Singleton `Theme` **généré** : couleurs (sombre/clair), typographie, espacements, rayons, durées. `Theme.dark` et `Theme.accentOverride` sont modifiables à l'exécution. |
| `Vinx.Controls` | `Label`, `Surface`, `Elevation`, `Button`, `IconButton`, `AppIcon`, `Icon` (C++), `Switch`, `Slider`, `SegmentedControl`, `Tile`, `Popover`, `Menu`, `MenuItem` |
| `vinx-gallery` | Présente tous les composants ; options `--light`, `--open cc\|menu`, `--screenshot fichier.png` |

Règles : aucun composant ne code de valeur de style en dur (tout vient de `Theme`) ; chaque contrôle
est utilisable au clavier (Tab, Espace/Entrée, flèches) et expose un rôle d'accessibilité.
Le flou d'arrière-plan des surfaces sera fourni par l'effet *blur* de KWin, pas par le QML.

## Construire et tester

Dépendances (Debian 13) :

```bash
sudo apt install cmake python3 qt6-base-dev qt6-declarative-dev qt6-svg-dev qml6-module-qtquick qml6-module-qtquick-window qml6-module-qtqml-workerscript qml6-module-qttest
```

```bash
cmake -S shell -B build/shell && cmake --build build/shell -j
```

```bash
ctest --test-dir build/shell --output-on-failure
```

```bash
./build/shell/gallery/vinx-gallery
```

Paquet Debian (tests inclus) :

```bash
cd shell && dpkg-buildpackage -us -uc -b
```

Compatible Qt 6.4 (Ubuntu 24.04) à 6.8 (Debian 13). La CI ([`vinx-shell`](../.github/workflows/shell.yml))
construit le paquet sur Debian 13, lance les tests et publie des captures de la galerie.
Le paquet est aussi intégré à l'ISO : *VinX Design System* apparaît dans le menu des applications.

## Modifier le style

- Couleurs, tailles, durées : `branding/tokens.toml`, puis recompiler.
- Icônes : `branding/icons/*.svg` (trait `currentColor`, grille 24 px). `node shell/tools/export_icons.js`
  régénère ce dossier depuis le jeu d'icônes de la maquette.
