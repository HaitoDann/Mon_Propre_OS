#!/bin/sh
# vinx-greeter-sync (exécuté en administrateur sans mot de passe) : seules deux valeurs connues passent,
# et le fichier écrit ne contient que ces deux clés. VINX_GREETER_DIR : dossier de test (pkexec vide
# l'environnement, ce raccourci n'existe donc pas en production).
tool=$1
fail=0
refuse() { if VINX_ADMIN_CHECK=1 sh "$tool" "$@" >/dev/null 2>&1; then echo "accepté à tort : $*"; fail=1; fi; }
accept() { if ! VINX_ADMIN_CHECK=1 sh "$tool" "$@" >/dev/null 2>&1; then echo "refusé à tort : $*"; fail=1; fi; }
accept light vert
accept dark graphite
refuse
refuse light
refuse sombre vert
refuse dark rouge
refuse dark "vert
x=1"
refuse dark vert extra
refuse -h vert
dir=$(mktemp -d)
VINX_GREETER_DIR=$dir sh "$tool" dark lagon || fail=1
expected=$(printf '[General]\ndark=true\naccent=lagon')
[ "$(cat "$dir/theme.conf.user")" = "$expected" ] || { echo "contenu inattendu"; cat "$dir/theme.conf.user"; fail=1; }
[ "$(find "$dir" -name '.theme*' | wc -l)" = 0 ] || { echo "fichier temporaire restant"; fail=1; }
rm -rf "$dir"
[ "$fail" = 0 ] && echo "vinx-greeter-sync : OK"
exit $fail
