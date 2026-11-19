# VinX OS — distribution Linux de bureautique

Distribution basée sur **Debian 13 « trixie »** (amd64), pensée pour la bureautique et la
productivité. Trois piliers : **simplicité, ergonomie, stabilité**.

Identité : thème clair, **vert du logo `#10DD8C`**, police IBM Plex Sans, design industriel sobre
([docs/DESIGN.md](docs/DESIGN.md)).

## Ce que contient VinX

- **Bureau VinX** (`vinx-shell`, Qt 6 / QML) sur KWin (Wayland) : barre supérieure minimale,
  dock, centre de contrôle (Wi-Fi, son, Bluetooth…), notifications, recherche globale, widgets,
  menu global d'application, verrouillage d'écran.
- **Applications VinX** : Paramètres (pages natives : écrans, Wi-Fi, son, énergie, imprimantes,
  pilotes, utilisateurs, sauvegarde, dépannage, mises à jour…), Store (Flathub + dépôt Debian,
  mises à jour en arrière-plan), Fichiers (interface VinX sur KIO), Bienvenue.
- **Système** : installateur Calamares (chiffrement, Secure Boot), instantanés Timeshift,
  dépôt APT VinX signé, écrans de démarrage et de connexion VinX.

## Structure

| Dossier | Rôle |
|---|---|
| `shell/` | **Tout le code VinX** : shell, applications (`apps/`), modules QML (`qml/Vinx/…`), session, outils système, thème SDDM, tests, paquet Debian `vinx-shell` |
| `branding/` | Identité : tokens, logo, icônes, fonds d'écran, écrans de démarrage, police |
| `distro/` | Construction de l'ISO (live-build), dépôt APT, test de démarrage |
| `docs/` | Design, UX, architecture, roadmap, recette 1.0, guides, décisions (ADR) |
| `web/` | Site de présentation (page `vinxlabs.fr/VinX-OS/`) |

## Démarrer

| Besoin | Où |
|---|---|
| Construire l'ISO | `sudo ./distro/build.sh` (Debian 13) — [ADR 0007](docs/adr/0007-construction-iso.md) |
| Installer VinX | [docs/INSTALL.md](docs/INSTALL.md) |
| Faire évoluer VinX depuis VinX | `vinx-dev` — [docs/DEV.md](docs/DEV.md) |
| Dépôt de mises à jour | [docs/APT.md](docs/APT.md) |
| Tests | [docs/TESTS.md](docs/TESTS.md) |
| Reprendre le projet (contexte complet) | [CLAUDE.md](CLAUDE.md) |

## Documentation

[Design](docs/DESIGN.md) · [UX](docs/UX.md) · [Architecture](docs/ARCHITECTURE.md) ·
[Roadmap](docs/ROADMAP.md) · [Décisions (ADR)](docs/adr/)

## Licence

Code sous [GPL-3.0-or-later](LICENSE). Visuels sous CC BY-SA 4.0 ; logo et nom « VinX OS » réservés
(voir [branding/LICENSE.md](branding/LICENSE.md) et [ADR 0012](docs/adr/0012-licence.md)).
