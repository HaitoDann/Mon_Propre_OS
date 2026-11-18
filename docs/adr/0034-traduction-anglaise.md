# ADR 0034 — Traduction anglaise

- **Statut** : accepté
- **Date** : 2026-11-18

## Décision

- Mécanisme standard de Qt : textes source en français (`qsTr` / `tr`), catalogue unique
  `shell/translations/vinx_en.ts` (extrait par `lupdate`), compilé en `vinx_en.qm` (lrelease,
  `qt6-l10n-tools`) et installé dans `/usr/share/vinx/translations`.
- Chargé au démarrage de chaque programme VinX (`common/vinxi18n.h`) : préférence
  `interface/language` (« », « fr », « en ») ; « automatique » suit la langue du système ; toute
  langue autre que le français charge l'anglais. La locale par défaut passe en `en_GB` (dates, jours).
- Traductions maintenues dans des dictionnaires Python (`translations/en_*.py`) reportés par
  `tools/fill_translations.py` ; test `translations-complete` en ctest.
- Paramètres → Apparence → Langue ; noms anglais des lanceurs (`Name[en]` des `.desktop`).
- Les initiales des jours du calendrier viennent de la locale (plus de lettres codées en dur).

## Conséquences

Voir « Pas encore traduit » dans `docs/TRADUCTION.md`.
