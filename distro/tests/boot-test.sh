#!/bin/sh
# Test de démarrage de l'ISO : la démarre dans QEMU (mode live), attend que le bureau VinX
# soit affiché, et enregistre des captures d'écran et le journal de la console série.
#
#   distro/tests/boot-test.sh ISO DOSSIER_SORTIE [DÉLAI_EN_SECONDES]
#
# Réussite : « Reached target graphical.target » puis « vinx-shell: prêt » sur la console série.
# Utilisé par .github/workflows/iso.yml ; fonctionne aussi en local (qemu-system-x86, socat,
# imagemagick ou netpbm pour les captures).
set -eu
ISO=$(realpath "$1")
OUT=$(realpath -m "$2")
LIMIT=${3:-900}
mkdir -p "$OUT"
WORK=$(mktemp -d)
QPID=""
trap 'kill "$QPID" 2>/dev/null || true; rm -rf "$WORK"' EXIT

# Noyau et initrd du live, pour ajouter la console série aux paramètres de démarrage.
xorriso -osirrox on -indev "$ISO" -extract /live "$WORK/live" >/dev/null 2>&1
KERNEL=$(find "$WORK/live" -maxdepth 1 -name 'vmlinuz*' | sort | tail -n 1)
INITRD=$(find "$WORK/live" -maxdepth 1 -name 'initrd*' | sort | tail -n 1)
if [ -z "$KERNEL" ] || [ -z "$INITRD" ]; then echo "Noyau ou initrd introuvable dans l'ISO" >&2; exit 1; fi

ACCEL=tcg
[ -w /dev/kvm ] && ACCEL=kvm
echo "==> Démarrage de l'ISO (accélération : $ACCEL, délai : ${LIMIT} s)"
qemu-system-x86_64 -machine accel=$ACCEL -m 4096 -smp 2 \
	-cdrom "$ISO" -kernel "$KERNEL" -initrd "$INITRD" \
	-append "boot=live components locales=fr_FR.UTF-8 keyboard-layouts=fr username=vinx hostname=vinx-os console=tty0 console=ttyS0,115200 systemd.journald.forward_to_console=1" \
	-vga virtio -display none -serial "file:$OUT/console.log" \
	-monitor "unix:$WORK/monitor.sock,server,nowait" &
QPID=$!

shot() {   # shot NOM : capture d'écran PNG
	printf 'screendump %s\n' "$WORK/$1.ppm" | socat - "UNIX-CONNECT:$WORK/monitor.sock" >/dev/null 2>&1 || return 0
	sleep 1
	if command -v convert >/dev/null; then convert "$WORK/$1.ppm" "$OUT/$1.png" 2>/dev/null || true
	elif command -v pnmtopng >/dev/null; then pnmtopng "$WORK/$1.ppm" > "$OUT/$1.png" 2>/dev/null || true
	else cp "$WORK/$1.ppm" "$OUT/"; fi
}

start=$(date +%s); boot=0; shell=0; n=0
while [ $(( $(date +%s) - start )) -lt "$LIMIT" ]; do
	sleep 15
	kill -0 "$QPID" 2>/dev/null || { echo "QEMU s'est arrêté" >&2; break; }
	n=$((n + 1)); shot "$(printf 'ecran-%02d' "$n")"
	grep -q "Reached target graphical.target" "$OUT/console.log" 2>/dev/null && [ "$boot" = 0 ] && { boot=1; echo "==> Système démarré ($(( $(date +%s) - start )) s)"; }
	if grep -q "vinx-shell.*prêt" "$OUT/console.log" 2>/dev/null; then
		shell=1
		echo "==> Bureau VinX affiché ($(( $(date +%s) - start )) s)"
		sleep 20; shot bureau   # laisse le temps au dock et au fond d'écran
		break
	fi
done
shot final

{
	echo "Démarrage du système : $([ $boot = 1 ] && echo OK || echo ÉCHEC)"
	echo "Bureau VinX          : $([ $shell = 1 ] && echo OK || echo ÉCHEC)"
	echo "Erreurs QML / plantages relevés :"
	grep -E "vinx-shell.*(arrêt anormal|TypeError|ReferenceError|is not installed|unavailable)" "$OUT/console.log" | head -20 || true
} | tee "$OUT/resume.txt"

[ "$boot" = 1 ] && [ "$shell" = 1 ]
