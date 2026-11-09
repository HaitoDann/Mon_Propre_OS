#!/usr/bin/env bash
# Génère les images PNG du système à partir des sources SVG de branding/.
# Usage : render-assets.sh <dossier includes.chroot> <dossier assets de démarrage>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
B="$ROOT/branding"
CHROOT="$1"
BOOT="$2"

command -v rsvg-convert >/dev/null || { echo "rsvg-convert manquant (paquet librsvg2-bin)" >&2; exit 1; }
r() { rsvg-convert "$@"; }

mkdir -p "$BOOT"

# Fonds d'écran (paquets de fonds d'écran Plasma)
for w in VinX:vinx-nebula VinX-Minimal:vinx-nebula-minimal; do
	dir="$CHROOT/usr/share/wallpapers/${w%%:*}/contents"
	src="$B/wallpaper/${w##*:}.svg"
	mkdir -p "$dir/images"
	r -w 3840 -h 2160 "$src" -o "$dir/images/3840x2160.png"
	r -w 1920 -h 1080 "$src" -o "$dir/images/1920x1080.png"
	r -w 400 -h 225 "$src" -o "$dir/screenshot.png"
done

# Logos
mkdir -p "$CHROOT/usr/share/pixmaps" "$CHROOT/usr/share/icons/hicolor/256x256/apps" \
	"$CHROOT/usr/share/plymouth/themes/vinx" "$CHROOT/usr/share/images/vinx" "$CHROOT/etc/calamares/branding/vinx"
r -w 512 "$B/logo/vinx-logo.svg" -o "$CHROOT/usr/share/pixmaps/vinx-logo.png"
r -w 256 -h 256 --keep-aspect-ratio "$B/logo/vinx-logo-gradient.svg" -o "$CHROOT/usr/share/icons/hicolor/256x256/apps/vinx-logo.png"

# Écran de démarrage Plymouth (filigrane centré)
r -w 220 "$B/logo/vinx-logo-gradient.svg" -o "$CHROOT/usr/share/plymouth/themes/vinx/watermark.png"

# Installateur Calamares
CAL="$CHROOT/etc/calamares/branding/vinx"
r -w 160 "$B/logo/vinx-logo-gradient.svg" -o "$CAL/logo.png"
r -w 560 "$B/logo/vinx-logo-gradient.svg" -o "$CAL/welcome.png"

# GRUB du système installé + menus de démarrage du live
r -w 1920 -h 1080 "$B/boot/splash-1920x1080.svg" -o "$CHROOT/usr/share/images/vinx/grub.png"
r -w 1920 -h 1080 "$B/boot/splash-1920x1080.svg" -o "$BOOT/grub-splash.png"
r -w 640 -h 480 "$B/boot/splash-640x480.svg" -o "$BOOT/isolinux-splash.png"
cp "$B/boot/splash-640x480.svg" "$BOOT/isolinux-splash.svg"

echo "Images générées."
