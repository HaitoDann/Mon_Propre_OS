#!/bin/sh
# Test de vinx-release (ADR 0040) : version du paquet dans vinx-release, os-release et issue.
set -eu
SCRIPT=$1
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/etc" "$T/usr/lib"
cat > "$T/usr/lib/os-release" <<'OS'
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION_CODENAME=trixie
ID=debian
OS
VINX_RELEASE_ROOT=$T VINX_RELEASE_VERSION=1.2.3 sh "$SCRIPT"
grep -qx 'VINX_VERSION="1.2.3"' "$T/etc/vinx-release"
grep -qx 'PRETTY_NAME="VinX OS 1.2.3 (Debian 13 trixie)"' "$T/usr/lib/os-release"
grep -qx 'NAME="VinX OS"' "$T/usr/lib/os-release"
grep -qx 'ID=debian' "$T/usr/lib/os-release"
# Deuxième passage (mise à jour) : une seule ligne VINX_VERSION, la nouvelle.
VINX_RELEASE_ROOT=$T VINX_RELEASE_VERSION=1.2.4 sh "$SCRIPT"
[ "$(grep -c '^VINX_VERSION=' "$T/usr/lib/os-release")" = 1 ]
grep -qx 'VINX_VERSION="1.2.4"' "$T/usr/lib/os-release"
grep -q '^VinX OS 1.2.4 ' "$T/etc/issue"
echo "vinx-release : OK"
