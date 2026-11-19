# VinX OS — contexte de reprise

Ce fichier est lu au début de chaque conversation. Il résume le projet, les préférences de
l'utilisateur et la façon de travailler. Détails : `README.md`, `docs/`.

## Le projet

Distribution **Debian 13 « trixie »** (amd64) de bureautique, avec son **propre bureau** (« VinX »)
écrit en **Qt 6 / QML / C++** sur l'infrastructure KDE Plasma 6 (KWin Wayland, kscreenlocker,
libtaskmanager, KIO, appmenu ; `plasmashell` est remplacé par `vinx-shell`).
Piliers : simplicité, ergonomie, stabilité. Licence GPL-3.0-or-later (ADR 0012).

L'utilisateur **utilise VinX au quotidien sur son portable** et le fait évoluer avec `vinx-dev`.
Il construit les ISO en local sur une machine **Debian 13** (`sudo ./distro/build.sh`).

## Préférences de l'utilisateur (à respecter)

- **Toujours répondre en français**, interface en français.
- Qualité plutôt que vitesse ; architecture propre, documentée, modulaire ; **un ADR par décision**
  structurante (`docs/adr/NNNN-*.md`).
- **Pas de changement d'architecture majeur sans validation.** Pour le design : montrer des
  **maquettes ou captures avant/après** et laisser choisir (il aime voir avant de décider).
- **Économiser les minutes GitHub Actions** : commiter en local, **pousser une fois par lot**.
  **Plus aucune ISO construite par GitHub Actions** (`iso.yml` seulement à la demande manuelle de
  l'utilisateur) : l'utilisateur construit l'ISO en local et met à jour son portable avec `vinx-dev`.
- Rapporter honnêtement ce qui n'a **pas** pu être testé (pas de matériel réel ici).

## Identité visuelle (ADR 0018 — en vigueur)

Thème **clair** par défaut, **vert du logo `#10DD8C`** comme accent par défaut (encre `#06130D` dessus,
`#0A7F51` pour le texte vert) ; 8 accents au choix + « Automatique » (ADR 0021), le fond « VinX Logo »
est dessiné en direct à la couleur d'accent, **IBM Plex Sans** (fournie dans `branding/fonts`), formes douces,
icônes « tuile neutre + pictogramme à l'encre + point de couleur », logos officiels pour les
applications tierces, fond « VinX Logo » (logo vert sur grille de points). Règles complètes :
**`docs/DESIGN.md`**. Valeurs : **`branding/tokens.toml`** → `Theme.qml` (généré).
Abandonnés (ne pas réintroduire) : violet/indigo, biseau partout, étiquettes en police technique.

## Organisation du code

| Chemin | Contenu |
|---|---|
| `shell/qml/Vinx/Theme` | `Theme.qml` généré par `shell/tools/gen_theme.py` |
| `shell/qml/Vinx/Controls` | Composants : Button, Switch, Slider, Bevel (forme), Surface, Popover, Menu, AppIcon… |
| `shell/qml/Vinx/System` | Singletons C++ : Network, Wifi (nmcli), Audio (wpctl), Bluetooth, Battery, Session, Preferences, Notifications, Flatpak, DebianPackages, Updates, Printers, Drivers, Accounts, Diagnostics, MenuBridge… ; analyseurs testés `sysparse.h`, `diagparse.h`, `updateparse.h`, `wpctl.h` |
| `shell/qml/Vinx/Shell` | Bureau : TopBar, Dock, ControlCenter, Toasts, Panels, Search, WifiNetworks, DisplayHotplug… |
| `shell/src/main.cpp` | Process `vinx-shell` (fenêtres layer-shell par écran) |
| `shell/apps/` | `settings` (pages *Page.qml), `store`, `files` (KIO), `welcome`, `updates` (Mises à jour), `terminal` (Qt Widgets + QTermWidget, compilé seulement en CI Debian) |
| `shell/windowtheme/` | `vinx-window-theme` : décoration de fenêtre Aurorae « pastilles » générée (accent, clair/sombre) |
| `shell/polkitagent/` | `vinx-polkit-agent` : fenêtre de mot de passe administrateur (polkit-qt6, facultatif) |
| `shell/system/` | `vinx-admin` (pkexec, polkit), `vinx-update`, `vinx-snapshots`, `vinx-backup` (documents), `vinx-dev` |
| `shell/translations/`, `shell/common/vinxi18n.h` | Traduction anglaise : `vinx_en.ts` + dictionnaires `en_*.py` ; **tout nouveau texte doit être traduit** (`tools/update_translations.sh`, test `translations-complete`, docs/TRADUCTION.md) |
| `shell/session/` | Session `vinx.desktop`, `vinx-session`, autostart avec relance |
| `shell/sddm/vinx`, `shell/lockscreen` | Connexion et verrouillage |
| `shell/tests/` | Tests QML (qmltestrunner) et C++ (QtTest) |
| `distro/` | ISO : `build.sh`, `live/` (live-build), hooks, `scripts/` (APT, assets), `tests/boot-test.sh` |
| `web/VinX-OS/` | Site de présentation (à copier dans le dépôt `vinx-labs`, voir `web/README.md`) |
| `.github/workflows/` | `shell.yml` (paquet + tests, à chaque poussée sur shell/), `iso.yml` (ISO + test de démarrage QEMU, déclenchement manuel uniquement), `apt-repo.yml` (étiquette `shell-v*`), `checks.yml` |

Préférences utilisateur : `~/.config/vinx/shell.ini` (QSettings, clés `section/clé`).

## Conventions pour chaque modification

1. Coder, puis **construire et tester en local** :
   `cmake -S shell -B <scratchpad>/shell-build && cmake --build <scratchpad>/shell-build -j8 && (cd <scratchpad>/shell-build && ctest)`.
2. Vérifier visuellement : `QT_QPA_PLATFORM=offscreen ./src/vinx-shell --demo --open control --screenshot x.png`,
   `./apps/settings/vinx-settings --page <page> --screenshot x.png`, `./apps/store/vinx-store --search debian:gimp --screenshot x.png`.
   Pour simuler du matériel (nmcli, kscreen-doctor, lpstat, lspci…), mettre de fausses commandes en tête de `PATH`.
3. **Monter la version** : `shell/CMakeLists.txt` (VERSION) + entrée en tête de `shell/debian/changelog`.
4. ADR si décision structurante ; mettre à jour `docs/` concernés.
5. Commit en français avec les lignes d'attribution demandées ; **une poussée par lot** sur la branche
   de travail ; vérifier ensuite le workflow `shell.yml` (Debian 13) et corriger s'il échoue.

## Pièges connus

- Local : Ubuntu, **Qt 6.4**, **sans KIO, LayerShellQt ni QTermWidget Qt 6** (code compilé seulement en CI Debian, Qt 6.8).
  Le code KIO de Fichiers, layer-shell du dock et le Terminal VinX ne se vérifient qu'en CI.
- Couleurs VinX en C++ : `vinxtokens.h` généré (cible `vinx::tokens`) depuis `tokens.toml`.
- Les dépôts Debian (`deb.debian.org`) sont bloqués ici : impossible d'installer des paquets trixie localement.
- Vérifier les **noms de paquets Debian** (ex. `kde-config-gtk-style`, pas `kde-gtk-config` ;
  `fonts-ibm-plex` indisponible → police fournie dans le dépôt).
- Tests : `VINX_TASKS_BACKEND=preview`, `XDG_CONFIG_HOME` isolé, `LANG=C.UTF-8`.
- Qt 6.4 : import explicite du module courant pour les types C++ ; pas de `Qt.alpha` (utiliser `Qt.rgba`).
- L'agent ne peut ni déclencher `workflow_dispatch`, ni pousser d'étiquette, ni créer de secret GitHub.

## En attente

- **Phase de consolidation 1.0** (ADR 0039, gel des fonctions) : suivre `docs/ROADMAP.md` et `docs/RECETTE.md` ;
  l'utilisateur envoie ses retours avec `vinx-dev rapport`. Branche principale : `main`.

- **Dépôt APT** : actif depuis le 18/11/2026 (`https://haitodann.github.io/VinX_OS/apt`, clé dans `distro/keys`).
  Publier = monter la version + étiquette `shell-vX.Y.Z` poussée par l'utilisateur (ou « Run workflow »).
- **Retours de test sur le portable** (jamais testé sur matériel réel) : Wi-Fi natif, écrans et
  bulle de branchement, imprimantes, utilisateurs, pilotes, dépannage, recherche Debian du Store,
  fiche détaillée d'application, mises à jour en arrière-plan, couleurs du menu GRUB.
- **Lot 2 « sans KDE »** : fait (ADR 0028) — extinction et bulles reprises par vinx-shell (services D-Bus KDE),
  agent polkit VinX (libpolkit-qt6-1-dev). Boutons « Avancé… » remplacés (ADR 0030) ;
  restent : comptes en ligne et réseau expert (802.1X, proxy).
- **À vérifier sur une nouvelle ISO** : installation en btrfs, instantanés automatiques, entrée « revenir à un
  état précédent » du menu de démarrage (grub-btrfs, ADR 0031).
- Ensuite : version publique 1.0 (site, ISO signée, guide). Traduction anglaise faite (ADR 0034) ; reste le
  catalogue du Store, les noms d'accents et les messages des scripts.
