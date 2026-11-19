#!/bin/sh
# Test de fumée : chaque page des Paramètres et chaque application VinX s'ouvre hors écran sans
# erreur QML (TypeError, ReferenceError, boucle de liaison, affectation invalide…).
# Usage : apps-smoke.sh DOSSIER_DE_BUILD   (préférences isolées, langue française)
set -u
B=$1
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export XDG_CONFIG_HOME="$T/config" XDG_STATE_HOME="$T/state" QT_QPA_PLATFORM=offscreen LANG=C.UTF-8 VINX_TASKS_BACKEND=preview
mkdir -p "$XDG_CONFIG_HOME"
PATTERN='TypeError|ReferenceError|Binding loop|Unable to assign|is not defined|Cannot read property|Cannot call method|is not a function|Non-existent attached|Cannot assign|Type .* unavailable|failed to load component|is not a type'
fail=0
# Deux passes : avec les outils du système (données réelles), puis sans aucun (PATH vide : nmcli,
# kscreen-doctor, vinx-backup… absents, comme dans le conteneur de la CI) ; aucune page ne doit
# alors produire d'erreur.
run() {
	name=$1; shift
	run_once "$name" "$@"
	run_once "$name-sans-outils" env PATH=/nonexistent "$@"
}
run_once() {
	name=$1; shift
	out=$(timeout 30 "$@" --screenshot "$T/$name.png" 2>&1)
	bad=$(printf '%s\n' "$out" | grep -E "$PATTERN" | sort -u)
	if [ -n "$bad" ] || [ ! -s "$T/$name.png" ]; then
		echo "== $name"; printf '%s\n' "${bad:-pas de capture}"; fail=1
	fi
}
for p in appearance wallpaper desktop dock notifications office displays sound power network printers drivers \
	accessibility keyboard datetime users backup troubleshoot updates about; do
	run "settings-$p" "$B/apps/settings/vinx-settings" --page "$p"
done
for a in store/vinx-store files/vinx-files updates/vinx-updates welcome/vinx-welcome monitor/vinx-monitor; do
	[ -x "$B/apps/$a" ] && run "$(basename "$a")" "$B/apps/$a"
done
run shell "$B/src/vinx-shell" --preview
for o in control system calendar; do run "shell-$o" "$B/src/vinx-shell" --preview --open "$o"; done
[ "$fail" = 0 ] && echo "applications : aucune erreur QML"
exit "$fail"
