# distro — construction de l'ISO VinX OS

Phase 1 de la [roadmap](../docs/ROADMAP.md) : une image **live et installable** basée sur
Debian 13 « trixie » (amd64), avec un bureau Plasma provisoire habillé aux couleurs de VinX OS.

## Construire l'ISO

**Option 1 — GitHub Actions (recommandé).** Le workflow [`ISO VinX OS`](../.github/workflows/iso.yml)
se lance à chaque modification de `distro/` ou `branding/` (ou manuellement depuis l'onglet *Actions*).
L'ISO et sa somme SHA-256 sont téléchargeables dans les *artefacts* du run (≈ 40–60 min).

**Option 2 — sur votre machine Linux avec Docker :**

```bash
sudo ./distro/docker-build.sh
```

**Option 3 — directement sur Debian 13 :**

```bash
sudo apt install live-build librsvg2-bin rsync
sudo ./distro/build.sh
```

Le résultat est dans `distro/out/vinx-os-<version>-amd64.iso`.

## Tester

```bash
qemu-system-x86_64 -enable-kvm -m 4096 -smp 2 -cdrom distro/out/vinx-os-0.1-amd64.iso
```

Ou VirtualBox / GNOME Boxes, ou une clé USB (`dd` ou Ventoy). Session live : utilisateur `vinx`
(mot de passe `live`), connexion automatique dans la session **VinX OS** ; Plasma reste disponible
à l'écran de connexion. L'icône « Installer VinX OS » lance Calamares.

Premier lancement épuré : pas de Centre de bienvenue KDE (remplacé par l'assistant VinX), pas de pages
d'accueil Firefox ni de télémétrie (`/etc/firefox-esr/policies`), pas de bandeau « nouveautés » dans
LibreOffice (`/etc/libreoffice/registry/vinx.xcd`).

## Contenu de l'image

| Domaine | Choix |
|---|---|
| Base | Debian 13 trixie, noyau amd64, firmwares (`non-free-firmware`), français par défaut |
| Bureau provisoire | Plasma 6 minimal + SDDM, disposition barre supérieure + dock centré |
| Applications | Firefox ESR, LibreOffice, Thunderbird, Dolphin, Okular, VLC… |
| Store provisoire | Discover + Flatpak (Flathub) — remplacé par le Store VinX en phase 5 |
| Installateur | Calamares, charte VinX |

## Personnalisation (branding)

Toutes les images sont **générées à la construction** depuis les SVG de [`branding/`](../branding)
par `scripts/render-assets.sh` : fonds d'écran, logos, écran de démarrage, menus de boot, installateur.

| Élément | Fichier(s) |
|---|---|
| Nom et version | `branding/brand.toml` → `/etc/vinx-release`, hook `0900-vinx-os-release` |
| Fond d'écran | `/usr/share/wallpapers/VinX*` |
| Apparence et disposition Plasma | `/usr/share/plasma/look-and-feel/org.vinx.desktop`, `/etc/xdg/kdeglobals`, `/etc/xdg/kwinrc` |
| Palette | `/usr/share/color-schemes/VinXDark.colors` |
| Écran de démarrage | Plymouth `vinx` (hook `0910-vinx-plymouth`) |
| Connexion | SDDM Breeze + fond VinX (`/etc/sddm.conf.d/10-vinx.conf`) |
| Démarrage | Menus du live (`build.sh`) et GRUB installé (`/etc/default/grub.d/vinx.cfg`) |
| Installateur | `/etc/calamares/branding/vinx` (hook `0920-vinx-calamares`) |

## Structure

```
distro/
├── build.sh              Construction (root, Debian 13)
├── docker-build.sh       Construction dans un conteneur Debian 13
├── scripts/render-assets.sh
└── live/                 Configuration live-build
    ├── auto/             config, build, clean
    └── config/
        ├── package-lists/    Paquets par thème
        ├── hooks/normal/     Scripts exécutés dans le système
        └── includes.chroot/  Fichiers copiés dans le système
```

## État et limites connues

- La configuration n'a **pas encore été validée par un premier démarrage** : le premier build CI
  servira de recette. Points à surveiller : propriétés de panneau Plasma (`lengthMode`, `floating`),
  splash du menu isolinux, renommage du lanceur Calamares.
- `/usr/lib/os-release` est modifié par un hook ; un paquet `vinx-base` le gérera proprement (phase 1+).
