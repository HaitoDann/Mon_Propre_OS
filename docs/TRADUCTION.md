# Traduction de VinX OS

Le français est la langue source. L'anglais est fourni (ADR 0034) ; toute autre langue système
affiche l'anglais.

## Ajouter ou modifier un texte

1. Écrire le texte en français avec `qsTr("…")` (QML) ou `tr("…")` (C++).
2. Ajouter sa traduction dans `shell/translations/en_*.py` (dictionnaire « français → anglais » ;
   pour un pluriel avec `%n`, un couple `("singulier", "pluriel")`).
3. Lancer `shell/tools/update_translations.sh` (lupdate puis report des traductions dans
   `shell/translations/vinx_en.ts`).

Le test `translations-complete` (ctest) échoue si un texte de l'interface n'a pas de traduction.

## Langue de l'interface

Paramètres → Apparence → Langue : Automatique (langue du système), Français, English
(préférence `interface/language`). Les applications VinX changent à leur prochaine ouverture ;
KDE et les autres applications à la prochaine ouverture de session (`plasma-localerc`).

## Pas encore traduit

- Messages d'erreur des outils en ligne de commande (`vinx-admin`, `vinx-snapshots`, `vinx-dev`) :
  destinés au terminal et au journal, ils restent en français.
- Diaporama de l'installateur et écran de connexion.

Traduits depuis la 0.26.11 : catalogue du Store (`Catalog.js`, contexte « Catalog »), noms des
couleurs d'accent (`common/accentnames.h`, contexte « Accent », test `accent-names`), notifications
de `vinx-update` et `vinx-backup` et nom du dossier de restauration (`system/vinx-i18n.sh` :
`T "français" "English"`, même règle de langue que les applications).
