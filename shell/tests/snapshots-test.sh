#!/bin/sh
# vinx-snapshots restore : appelle bien Timeshift avec un nom valide (une apostrophe mal placée
# rendait toute la branche inopérante) et refuse les noms douteux. Timeshift et logger factices ;
# la vérification « administrateur » est neutralisée sur une copie du script.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin"
printf '#!/bin/sh\necho "timeshift $*" >> "%s/calls"\n' "$T" > "$T/bin/timeshift"
printf '#!/bin/sh\n:\n' > "$T/bin/logger"
chmod +x "$T/bin/"*
sed 's/\[ "$(id -u)" = 0 \] ||/true ||/' "$1" > "$T/vs"
export PATH="$T/bin:$PATH"
sh "$T/vs" restore 2026-11-19_10-00-00 >/dev/null
grep -qx "timeshift --restore --snapshot 2026-11-19_10-00-00 --scripted --yes --skip-grub" "$T/calls"
for n in "../etc" "a;b" "x y" ""; do
	if sh "$T/vs" restore "$n" >/dev/null 2>&1; then echo "nom accepté à tort : [$n]" >&2; exit 1; fi
done
[ "$(wc -l < "$T/calls")" = 1 ]
echo "vinx-snapshots : OK"
