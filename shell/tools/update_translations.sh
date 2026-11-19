#!/bin/sh
# Met à jour le catalogue anglais après avoir ajouté ou modifié des textes (voir docs/TRADUCTION.md).
set -eu
cd "$(dirname "$0")/.."
LUPDATE=${LUPDATE:-/usr/lib/qt6/bin/lupdate}
"$LUPDATE" -silent -recursive -no-obsolete -extensions qml,js,cpp,h qml apps src common polkitagent lockscreen sddm gallery windowtheme \
	-ts translations/vinx_en.ts -source-language fr -target-language en
python3 tools/fill_translations.py en
