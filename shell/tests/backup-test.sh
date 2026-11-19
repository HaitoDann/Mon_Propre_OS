#!/bin/sh
# Test de vinx-backup : deux versions, fichiers inchangés partagés (liens physiques), restauration à part.
set -eu
SCRIPT=$1
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME="$T/home" XDG_CONFIG_HOME="$T/home/.config" XDG_STATE_HOME="$T/home/.local/state"
mkdir -p "$HOME/Documents" "$HOME/Images" "$XDG_CONFIG_HOME/vinx" "$T/media/Disque" "$T/bin"
# Faux xdg-user-dir et busctl (pas de session de bureau pendant les tests).
printf '#!/bin/sh\ncase "$1" in DOCUMENTS) echo "$HOME/Documents";; PICTURES) echo "$HOME/Images";; *) echo "$HOME";; esac\n' > "$T/bin/xdg-user-dir"
printf '#!/bin/sh\nexit 0\n' > "$T/bin/busctl"
chmod +x "$T/bin/"*
export PATH="$T/bin:$PATH"
# Aucun disque choisi : le minuteur (--if-due) sort sans erreur, une sauvegarde manuelle échoue.
printf '[backup]\nauto=true\n' > "$XDG_CONFIG_HOME/vinx/shell.ini"
sh "$SCRIPT" run --if-due
if sh "$SCRIPT" run 2>/dev/null; then echo "run sans disque aurait dû échouer" >&2; exit 1; fi

printf '[backup]\ndestination=%s\nfolders=DOCUMENTS PICTURES\nauto=true\n' "$T/media/Disque" > "$XDG_CONFIG_HOME/vinx/shell.ini"
echo "budget" > "$HOME/Documents/budget.txt"
echo "photo" > "$HOME/Images/photo.jpg"

sh "$SCRIPT" run
ROOT="$T/media/Disque/VinX-Sauvegarde/$(id -un)"
V1=$(date +%F)
test -f "$ROOT/$V1/Documents/budget.txt"
test -f "$ROOT/$V1/Images/photo.jpg"
sh "$SCRIPT" status | grep -q "\"result\":\"ok\""
sh "$SCRIPT" status | grep -q "\"$V1\""

# Version précédente simulée : la nouvelle partage les fichiers inchangés.
mv "$ROOT/$V1" "$ROOT/2026-01-01"
echo "nouveau" > "$HOME/Documents/lettre.txt"
sh "$SCRIPT" run
test -f "$ROOT/$V1/Documents/lettre.txt"
[ "$(stat -c %i "$ROOT/2026-01-01/Images/photo.jpg")" = "$(stat -c %i "$ROOT/$V1/Images/photo.jpg")" ]

# --if-due : rien à faire si la dernière sauvegarde a moins de 24 h.
touch "$ROOT/marqueur"
sh "$SCRIPT" run --if-due

# Restauration : copie à part, rien n'est écrasé.
echo "modifié" > "$HOME/Documents/budget.txt"
OUT=$(sh "$SCRIPT" restore 2026-01-01)
grep -q budget "$OUT/Documents/budget.txt"
grep -q modifié "$HOME/Documents/budget.txt"

# Disque débranché : --if-due ne fait rien et ne signale pas d'erreur.
sed -i "s#destination=.*#destination=$T/absent#" "$XDG_CONFIG_HOME/vinx/shell.ini"
sh "$SCRIPT" run --if-due
echo "vinx-backup : OK"
