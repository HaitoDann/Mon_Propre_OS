#!/bin/sh
# Crée la clé GPG qui signe le dépôt APT de VinX OS (à lancer UNE fois, sur ton poste).
#  - la clé publique est écrite dans distro/keys/vinx-archive-keyring.asc (à commiter) ;
#  - la clé privée est affichée pour être collée dans le secret GitHub APT_SIGNING_KEY,
#    puis à sauvegarder hors ligne (clé USB…). Ne jamais la commiter.
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
OUT="$ROOT/distro/keys/vinx-archive-keyring.asc"
mkdir -p "$(dirname "$OUT")"
[ -f "$OUT" ] && { echo "La clé publique existe déjà : $OUT" >&2; exit 1; }

GNUPGHOME=$(mktemp -d); export GNUPGHOME
trap 'rm -rf "$GNUPGHOME"' EXIT
gpg --batch --quiet --passphrase '' --quick-gen-key "VinX OS Archive <apt@vinx-os.invalid>" ed25519 sign 5y
FPR=$(gpg --list-keys --with-colons | awk -F: '/^fpr/ {print $10; exit}')
gpg --armor --export "$FPR" > "$OUT"
SECRET="$ROOT/vinx-apt-signing-key.SECRET.asc"
gpg --armor --export-secret-keys "$FPR" > "$SECRET"
chmod 600 "$SECRET"
echo "Clé publique : $OUT (à commiter)"
echo "Clé privée   : $SECRET"
echo "  1. Copie son contenu dans GitHub > Settings > Secrets and variables > Actions > New secret, nom APT_SIGNING_KEY"
echo "  2. Sauvegarde-la hors ligne, puis supprime-la : rm '$SECRET'"
