# ADR 0022 — Installation hors ligne : dépôt de paquets sur l'ISO

- **Statut** : accepté
- **Date** : 2026-11-17

## Contexte

Premier essai sur le portable (ISO 0.17) : l'installation échoue à l'étape
`bootloader-config` de calamares-settings-debian. Ce script installe GRUB dans le système cible
avec `apt-get install grub-efi-amd64` (UEFI) ou `grub-pc` (BIOS), plus `cryptsetup-initramfs`
si le disque est chiffré. L'étape `sources-media` pointe APT vers la clé
(`deb [trusted=yes] file:/run/live/medium trixie main`), mais notre ISO ne contenait aucun dépôt
(`--debian-installer none`) : APT est allé sur deb.debian.org, injoignable, et GRUB n'a pas été
installé (`/etc/default/grub` absent, `grub-mkconfig` en échec).

## Décision

- `distro/build.sh` construit un **petit dépôt APT sur l'ISO** (`/pool/main`, `/dists/trixie`,
  via `config/includes.binary`) : GRUB UEFI et BIOS, shim signé, efibootmgr, os-prober,
  cryptsetup(-initramfs), keyutils, avec la fermeture de leurs dépendances. Index
  `dpkg-scanpackages` + `Release` (`apt-ftparchive`) ; le dépôt est marqué `trusted=yes` par
  Debian.
- Le crochet `0920-vinx-calamares` modifie `sources-media` : pendant l'installation, les sources
  réseau du système cible sont mises de côté, APT n'utilise que la clé ; elles sont rétablies à
  `sources-media -u`, puis `sources-final` écrit le `sources.list` définitif.
- La CI de l'ISO vérifie que `grub-efi-amd64`, `grub-pc` et `cryptsetup-initramfs` sont dans
  l'index de l'ISO.

## Conséquences

- L'installation ne demande plus de connexion à Internet.
- L'ISO grossit de quelques dizaines de Mo.
- Le test automatique ne couvre que le démarrage du live, pas une installation complète :
  l'installation reste à valider sur le portable.
