#!/bin/sh
# Traduction anglaise complète : on réextrait les textes de l'interface dans une copie du catalogue,
# puis on vérifie qu'ils ont tous une traduction (tools/fill_translations.py échoue sinon).
set -eu
LUPDATE=$1 SRC=$2
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
cp "$SRC/translations/vinx_en.ts" "$T/vinx_en.ts"
# Seulement les sources (pas un éventuel dossier de construction placé dans l'arbre).
"$LUPDATE" -silent -recursive -no-obsolete -extensions qml,js,cpp,h \
	"$SRC/qml" "$SRC/apps" "$SRC/src" "$SRC/polkitagent" "$SRC/lockscreen" "$SRC/gallery" "$SRC/windowtheme" \
	-ts "$T/vinx_en.ts"
python3 "$SRC/tools/fill_translations.py" en "$T/vinx_en.ts"
