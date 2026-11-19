#!/bin/sh
# Chaque outil /usr/lib/vinx/NOM cité dans le code est installé par le paquet (vinx-update ne
# l'était pas : « Tout mettre à jour » échouait toujours). DESTDIR = installation de test.
set -eu
SRC=$1 DESTDIR=$2
missing=0
for name in $(grep -rhoE '/usr/lib/vinx/[A-Za-z0-9_-]+(\.sh)?' "$SRC/qml" "$SRC/apps" "$SRC/src" "$SRC/session" "$SRC/system" "$SRC/debian" 2>/dev/null \
		| sed 's|.*/||' | sort -u); do
	if [ ! -e "$DESTDIR/usr/lib/vinx/$name" ]; then echo "non installé : /usr/lib/vinx/$name" >&2; missing=1; fi
done
[ "$missing" = 0 ] && echo "outils /usr/lib/vinx : OK"
exit "$missing"
