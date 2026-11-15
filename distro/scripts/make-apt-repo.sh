#!/bin/sh
# Construit un dépôt APT signé à partir de paquets .deb.
# Usage : make-apt-repo.sh DOSSIER_DES_DEB DOSSIER_SORTIE [ID_CLÉ_GPG]
# Sans ID de clé, le dépôt n'est pas signé (tests locaux uniquement).
set -eu
DEBS=$1 OUT=$2 KEY=${3:-}
DIST=trixie COMP=main ARCH=amd64

mkdir -p "$OUT/pool/$COMP" "$OUT/dists/$DIST/$COMP/binary-$ARCH"
cp "$DEBS"/*.deb "$OUT/pool/$COMP/"
cd "$OUT"
apt-ftparchive packages "pool/$COMP" > "dists/$DIST/$COMP/binary-$ARCH/Packages"
gzip -9kf "dists/$DIST/$COMP/binary-$ARCH/Packages"
apt-ftparchive \
	-o APT::FTPArchive::Release::Origin="VinX OS" \
	-o APT::FTPArchive::Release::Label="VinX OS" \
	-o APT::FTPArchive::Release::Suite="$DIST" \
	-o APT::FTPArchive::Release::Codename="$DIST" \
	-o APT::FTPArchive::Release::Architectures="$ARCH" \
	-o APT::FTPArchive::Release::Components="$COMP" \
	release "dists/$DIST" > "dists/$DIST/Release"
if [ -n "$KEY" ]; then
	gpg --batch --yes --default-key "$KEY" --clearsign -o "dists/$DIST/InRelease" "dists/$DIST/Release"
	gpg --batch --yes --default-key "$KEY" -abs -o "dists/$DIST/Release.gpg" "dists/$DIST/Release"
fi
echo "Dépôt prêt dans $OUT"
