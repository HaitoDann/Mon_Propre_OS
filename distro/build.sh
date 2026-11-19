#!/usr/bin/env bash
# Construit l'image ISO de VinX OS.
# À lancer en root sur Debian 13 (trixie), ou via distro/docker-build.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DISTRO="$ROOT/distro"
WORK="$DISTRO/build"
OUT="$DISTRO/out"
# Version unique (ADR 0040) : celle du paquet vinx-shell, qui la réécrit aussi à chaque mise à jour APT.
VERSION="$(sed -n '1s/^[^(]*(\([^)~-]*\).*/\1/p' "$ROOT/shell/debian/changelog")"

[ "$(id -u)" -eq 0 ] || { echo "Ce script doit être lancé en root." >&2; exit 1; }
for cmd in lb debootstrap rsvg-convert rsync dpkg-buildpackage; do
	command -v "$cmd" >/dev/null || {
		echo "Commande manquante : $cmd" >&2
		echo "Installez : sudo apt install live-build debootstrap librsvg2-bin rsync dpkg-dev debhelper" >&2
		exit 1
	}
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
# Version affichée par l'installateur (« Remplacer une partition par VinX … »).
sed -i -E "s/^( *(short)?[vV]ersion(edName)?: *\")([A-Za-z ]*)[0-9][0-9.]*\"/\\1\\4$VERSION\"/" \
	"$WORK/config/includes.chroot/etc/calamares/branding/vinx/branding.desc"

# Paquets maison (vinx-shell…) construits puis installés dans l'image.
if [ -d "$ROOT/shell/debian" ]; then
	echo "==> Construction du paquet vinx-shell"
	# Dépendances de construction manquantes (nouvelle version du shell) : installées automatiquement.
	if ! (cd "$ROOT/shell" && dpkg-checkbuilddeps >/dev/null 2>&1); then
		echo "==> Installation des dépendances de construction de vinx-shell"
		apt-get update -qq
		apt-get build-dep -y "$ROOT/shell"
	fi
	(cd "$ROOT/shell" && dpkg-buildpackage -us -uc -b)
	mkdir -p "$WORK/config/packages.chroot"
	mv "$ROOT"/vinx-shell_*.deb "$WORK/config/packages.chroot/"
	# Symboles de débogage : inutiles dans l'image.
	rm -f "$WORK"/config/packages.chroot/vinx-shell-dbgsym_*.deb
	rm -f "$ROOT"/vinx-shell_*.buildinfo "$ROOT"/vinx-shell_*.changes
fi

# Dépôt APT VinX (mises à jour du shell sans réinstaller) : actif dès que la clé publique existe.
KEYRING="$DISTRO/keys/vinx-archive-keyring.asc"
if [ -f "$KEYRING" ]; then
	command -v gpg >/dev/null || { echo "Commande manquante : gpg (sudo apt install gnupg)" >&2; exit 1; }
	echo "==> Ajout du dépôt APT VinX"
	mkdir -p "$WORK/config/includes.chroot/usr/share/keyrings" "$WORK/config/includes.chroot/etc/apt/sources.list.d"
	gpg --dearmor < "$KEYRING" > "$WORK/config/includes.chroot/usr/share/keyrings/vinx-archive-keyring.gpg"
	cat > "$WORK/config/includes.chroot/etc/apt/sources.list.d/vinx.sources" <<SRC
Types: deb
URIs: ${VINX_APT_URL:-https://haitodann.github.io/VinX_OS/apt}
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/vinx-archive-keyring.gpg
SRC
else
	echo "!! Pas de clé distro/keys/vinx-archive-keyring.asc : dépôt APT VinX non configuré (voir docs/APT.md)"
fi

# Dépôt de paquets hors ligne sur l'ISO. L'installateur (calamares-settings-debian, étape
# « sources-media ») configure l'APT du système installé sur la clé (/run/live/medium) puis
# installe GRUB (grub-efi-amd64 en UEFI, grub-pc en BIOS) et, si le disque est chiffré,
# cryptsetup-initramfs. Sans ces paquets sur l'ISO, l'installation échoue hors connexion (ADR 0022).
echo "==> Dépôt hors ligne de l'installateur (GRUB, chiffrement)"
command -v dpkg-scanpackages >/dev/null && command -v apt-ftparchive >/dev/null || {
	apt-get update -qq
	apt-get install -y --no-install-recommends dpkg-dev apt-utils
}
OFFLINE_PKGS="grub-efi-amd64 grub-efi grub-efi-amd64-bin grub-efi-amd64-signed shim-signed grub-pc grub-pc-bin
	cryptsetup cryptsetup-initramfs keyutils efibootmgr os-prober"
MEDIA="$WORK/config/includes.binary"
rm -rf "$MEDIA/pool" "$MEDIA/dists"
mkdir -p "$MEDIA/pool/main" "$MEDIA/dists/trixie/main/binary-amd64"
apt-get update -qq
# Fermeture des dépendances (paquets réels uniquement : les virtuels sont entre < >).
DEPS="$(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks \
	--no-replaces --no-enhances $OFFLINE_PKGS | grep -E '^[a-z0-9]' | sort -u)"
(cd "$MEDIA/pool/main" && apt-get download $DEPS)
(cd "$MEDIA" && dpkg-scanpackages --multiversion pool/main /dev/null > dists/trixie/main/binary-amd64/Packages \
	&& gzip -9kf dists/trixie/main/binary-amd64/Packages \
	&& apt-ftparchive -o APT::FTPArchive::Release::Suite=trixie -o APT::FTPArchive::Release::Codename=trixie \
		-o APT::FTPArchive::Release::Components=main -o APT::FTPArchive::Release::Architectures=amd64 \
		release dists/trixie > "$WORK/Release.tmp" && mv "$WORK/Release.tmp" dists/trixie/Release)
for p in $OFFLINE_PKGS; do
	grep -q "^Package: $p\$" "$MEDIA/dists/trixie/main/binary-amd64/Packages" || { echo "Paquet hors ligne manquant : $p" >&2; exit 1; }
done
echo "    $(ls "$MEDIA/pool/main" | wc -l) paquets, $(du -sh "$MEDIA/pool" | cut -f1)"

echo "==> Génération des images"
"$DISTRO/scripts/render-assets.sh" "$WORK/config/includes.chroot" "$WORK/boot-assets"

cd "$WORK"
lb config

echo "==> Menus de démarrage du live aux couleurs de VinX OS"
cp -r /usr/share/live/build/bootloaders config/
cp boot-assets/grub-splash.png config/bootloaders/grub-pc/splash.png
cp boot-assets/isolinux-splash.png config/bootloaders/isolinux/splash.png
cp boot-assets/isolinux-splash.svg config/bootloaders/isolinux/splash.svg
# Fond clair VinX : texte à l'encre, sélection verte (le texte blanc d'origine serait illisible).
for f in config/bootloaders/isolinux/stdmenu.cfg config/bootloaders/syslinux_common/stdmenu.cfg; do
	[ -f "$f" ] && cat >> "$f" <<'MENU'
menu color title	* #ff141414 #00000000 none
menu color unsel	* #ff141414 #00000000 none
menu color sel		* #ff06130d #ff10dd8c none
menu color hotsel	* #ff06130d #ff10dd8c none
menu color tabmsg	* #ff5f5e5a #00000000 none
menu color timeout_msg	* #ff5f5e5a #00000000 none
menu color timeout	* #ff141414 #00000000 none
MENU
done
find config/bootloaders/grub-pc -type f \( -name '*.cfg' -o -name '*.txt' \) -print0 2>/dev/null | xargs -0 -r sed -i -E \
	-e 's/(color_normal=)[^ ]+/\1black\/black/' \
	-e 's/(color_highlight=)[^ ]+/\1green\/black/' \
	-e 's/(menu_color_normal=)[^ ]+/\1black\/black/' \
	-e 's/(menu_color_highlight=)[^ ]+/\1green\/black/' \
	-e 's/((item|title|message|label|text)[-_]color *[=:] *)"#[0-9A-Fa-f]{6}"/\1"#141414"/' \
	-e 's/(selected_item_color *[=:] *)"#[0-9A-Fa-f]{6}"/\1"#0A7A4E"/'
# Entrées du menu de démarrage : « VinX OS » au lieu de « Debian GNU/Linux » / « Live system ».
grep -rlE "Debian GNU/Linux|Live system" config/bootloaders | xargs -r sed -i \
	-e 's#Debian GNU/Linux#VinX OS#g' -e 's#Live system#VinX OS (live)#g'


echo "==> Construction (plusieurs dizaines de minutes)"
lb build

ISO="$OUT/vinx-os-$VERSION-amd64.iso"
if ! ls ./*.iso >/dev/null 2>&1; then
	echo "Échec : aucune image ISO produite. Voir le journal : $WORK/build.log" >&2
	exit 1
fi
mv -f ./*.iso "$ISO"
(cd "$OUT" && sha256sum "$(basename "$ISO")" > "$(basename "$ISO").sha256")
echo "==> Terminé : $ISO"
