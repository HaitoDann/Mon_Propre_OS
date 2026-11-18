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

- Noms et résumés du catalogue du Store (`apps/store/Catalog.js`) et noms des couleurs d'accent
  (`branding/tokens.toml`).
- Messages des scripts (`vinx-backup`, `vinx-update`, `vinx-dev`, notifications qu'ils envoient).
- Diaporama de l'installateur et écran de connexion.
