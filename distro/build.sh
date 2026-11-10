#!/usr/bin/env bash
# Construit l'image ISO de VinX OS.
# À lancer en root sur Debian 13 (trixie), ou via distro/docker-build.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DISTRO="$ROOT/distro"
WORK="$DISTRO/build"
OUT="$DISTRO/out"
VERSION="$(sed -n 's/^version *= *"\(.*\)"/\1/p' "$ROOT/branding/brand.toml")"

[ "$(id -u)" -eq 0 ] || { echo "Ce script doit être lancé en root." >&2; exit 1; }
for cmd in lb rsvg-convert rsync; do
	command -v "$cmd" >/dev/null || { echo "Commande manquante : $cmd (apt install live-build librsvg2-bin rsync)" >&2; exit 1; }
done

# Vérifie que tous les paquets demandés existent (échec rapide, liste complète).
if command -v apt-cache >/dev/null && grep -q trixie /etc/os-release 2>/dev/null; then
	echo "==> Vérification des listes de paquets"
	missing=""
	# shellcheck disable=SC2013 # un nom de paquet par mot
	for pkg in $(grep -hv '^\s*#' "$DISTRO"/live/config/package-lists/*.list.chroot); do
		apt-cache show "$pkg" >/dev/null 2>&1 || missing="$missing $pkg"
	done
	[ -z "$missing" ] || { echo "Paquets introuvables :$missing" >&2; exit 1; }
fi

echo "==> VinX OS $VERSION — préparation de $WORK"
mkdir -p "$WORK" "$OUT"
# Nettoyage par live-build (démonte proprement le chroot d'un build précédent).
if [ -d "$WORK/.build" ]; then (cd "$WORK" && lb clean --purge); fi

rsync -a --delete "$DISTRO/live/auto/" "$WORK/auto/"
rsync -a --delete "$DISTRO/live/config/" "$WORK/config/"
echo "VINX_VERSION=\"$VERSION\"" > "$WORK/config/includes.chroot/etc/vinx-release"

echo "==> Génération des images"
"$DISTRO/scripts/render-assets.sh" "$WORK/config/includes.chroot" "$WORK/boot-assets"

cd "$WORK"
lb config

echo "==> Menus de démarrage du live aux couleurs de VinX OS"
cp -r /usr/share/live/build/bootloaders config/
cp boot-assets/grub-splash.png config/bootloaders/grub-pc/splash.png
cp boot-assets/isolinux-splash.png config/bootloaders/isolinux/splash.png
cp boot-assets/isolinux-splash.svg config/bootloaders/isolinux/splash.svg

echo "==> Construction (plusieurs dizaines de minutes)"
lb build

ISO="$OUT/vinx-os-$VERSION-amd64.iso"
mv -f ./*.iso "$ISO"
(cd "$OUT" && sha256sum "$(basename "$ISO")" > "$(basename "$ISO").sha256")
echo "==> Terminé : $ISO"
