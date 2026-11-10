# vinx-shell — shell de bureau de VinX OS

Interface native de VinX OS, en **Qt 6 / QML**, au-dessus du compositeur **KWin** ([ADR 0002](../docs/adr/0002-qt6-qml-kwin.md)).
Référence UX : la [maquette](../prototype/) et le [guide UX](../docs/UX.md).

## État

| Étape | Contenu | État |
|---|---|---|
| 1. Socle | CMake, thème généré, paquet `.deb`, CI, galerie | ✅ |
| 2. Design system | `Vinx.Theme`, `Vinx.Controls` | ✅ |
| 3. Barre supérieure | `vinx-shell` : barre, centre de contrôle, calendrier, menu système | ✅ |
| 4. Dock | | à venir |
| 5. Session « VinX » | | à venir |

## Architecture

```
branding/tokens.toml ──gen_theme.py──▶ Vinx.Theme (singleton Theme)
branding/icons/*.svg ───────────────▶ Vinx.Controls (ressources, composant Icon)
                                          │
                      vinx-gallery ◀──────┤   (vitrine + recette visuelle)
                      vinx-shell   ◀──────┘   (barre supérieure)
Vinx.System (C++ : UPower, NetworkManager, BlueZ, WirePlumber, logind) ──▶ Vinx.Shell
```

| Module | Rôle |
|---|---|
| `Vinx.Theme` | Singleton `Theme` **généré** : couleurs (sombre/clair), typographie, espacements, rayons, durées. `Theme.dark` et `Theme.accentOverride` sont modifiables à l'exécution. |
| `Vinx.Controls` | `Label`, `Surface`, `Elevation`, `Button`, `IconButton`, `AppIcon`, `Icon` (C++), `Switch`, `Slider`, `SegmentedControl`, `Tile`, `Popover`, `Menu`, `MenuItem` |
| `Vinx.System` | Singletons C++ : `Battery` (UPower), `Network` (NetworkManager), `Bluetooth` (BlueZ), `Audio` (WirePlumber/`wpctl`), `Session` (logind : verrouiller, veille, redémarrer, éteindre ; lancement d'apps). Chaque service signale `available: false` s'il est absent. |
| `Vinx.Shell` | `TopBar`, `ControlCenter`, `CalendarPanel`, `Panels`, `ShellState`, fenêtres layer-shell et `Preview` |
| `vinx-shell` | Sous Wayland (KWin) : barre ancrée en haut (zone réservée de 34 px) + couche de panneaux. Sinon ou avec `--preview` : fenêtre d'aperçu. Options `--light`, `--open system\|control\|calendar`, `--screenshot fichier.png` |
| `vinx-gallery` | Présente tous les composants ; options `--light`, `--open cc\|menu`, `--screenshot fichier.png` |

Règles : aucun composant ne code de valeur de style en dur (tout vient de `Theme`) ; chaque contrôle
est utilisable au clavier (Tab, Espace/Entrée, flèches) et expose un rôle d'accessibilité.
Le flou d'arrière-plan des surfaces sera fourni par l'effet *blur* de KWin, pas par le QML.

## Construire et tester

Dépendances (Debian 13) :

```bash
sudo apt install cmake python3 qt6-base-dev qt6-declarative-dev qt6-svg-dev liblayershellqtinterface-dev qml6-module-qtquick qml6-module-qtquick-window qml6-module-qtqml-workerscript qml6-module-qttest
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

```bash
./build/shell/src/vinx-shell --preview
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

## Limites connues (v0.2)

- Le nom de l'application active (« Bureau ») et les menus d'application arriveront avec l'étape 4
  (liste des fenêtres fournie par KWin).
- Le son passe par l'outil `wpctl` (interrogé toutes les 4 s) ; une liaison PipeWire native suivra.
- Luminosité, notifications et recherche : étapes 6 et 7.
- Le mode layer-shell n'est compilé qu'avec LayerShellQt 6 (Debian 13) et sera validé dans la session « VinX » (étape 5).
