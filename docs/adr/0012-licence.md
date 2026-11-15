# ADR 0012 — Licence du projet

- **Statut** : accepté
- **Date** : 2026-11-15

## Contexte

Le projet doit pouvoir être distribué au public tout en protégeant le travail de son auteur :
une version modifiée ne doit pas pouvoir devenir fermée. Le shell s'appuie sur des briques KDE
sous GPL/LGPL (appmenu, libtaskmanager, kscreenlocker) et sur Debian.

## Décision

| Contenu | Licence |
|---|---|
| Code (shell, applications, scripts, configuration de l'ISO) | **GPL-3.0-or-later** (`LICENSE`) |
| Fonds d'écran, icônes, documentation | **CC BY-SA 4.0** |
| Logo et nom « VinX OS » | **Tous droits réservés** (marque, `branding/LICENSE.md`) |

## Conséquences

- Toute redistribution, modifiée ou non, doit fournir le code source sous la même licence (copyleft).
- La GPL-3 protège en plus contre le verrouillage matériel (« tivoïsation ») et inclut une licence de brevets.
- Compatible avec les dépendances KDE (GPL-2.0-or-later, LGPL) et Qt (LGPL-3).
- Un dérivé public doit changer de nom et de logo.
- Un contributeur extérieur conserve ses droits d'auteur ; ses contributions sont acceptées sous la même licence.
