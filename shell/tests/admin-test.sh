#!/bin/sh
# vinx-admin (exécuté en administrateur) : refuse tout argument douteux. VINX_ADMIN_CHECK=1 :
# validation seule, sans rien exécuter.
set -u
A=$1
export VINX_ADMIN_CHECK=1
fail=0
ok()  { sh "$A" "$@" 2>/dev/null || { echo "refusé à tort : $*" >&2; fail=1; }; }
bad() { if sh "$A" "$@" 2>/dev/null; then echo "accepté à tort : $*" >&2; fail=1; fi; }
NL='
'
ok install firmware-iwlwifi nvidia-driver
ok printer-add Bureau_HP "ipp://192.168.1.20/ipp/print"
ok printer-remove Bureau_HP
bad install -o
bad install "--allow-unauthenticated"
bad install "firmware${NL}-o"
bad install "a b"
bad printer-add "-x" "ipp://h/p"
bad printer-add "ok${NL}x" "ipp://h/p"
bad printer-add q "file:///etc/shadow"
bad printer-add q "ipp://h/p;rm -rf /"
bad printer-add q "ipp://h/p${NL}x"
bad printer-remove "../x"
bad unknown
[ "$fail" = 0 ] && echo "vinx-admin : OK"
exit "$fail"
