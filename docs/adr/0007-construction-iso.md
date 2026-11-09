# ADR 0007 — Construction de l'ISO avec live-build en conteneur

- **Statut** : accepté
- **Date** : 2026-11-09

## Contexte
Il faut une ISO reproductible, construisible par n'importe quel contributeur et automatiquement.

## Décision
- Outil officiel Debian **live-build**, configuration versionnée dans `distro/live/`.
- Construction dans un **conteneur `debian:trixie`** (`docker-build.sh`), exécutée par **GitHub Actions**.
- Images générées à la construction depuis les SVG de `branding/` (aucun PNG binaire versionné côté distro).
- Phase 1 : Plasma 6 minimal thémé + Discover/Flatpak comme store provisoire, Calamares comme installateur.

## Conséquences
Build identique en local et en CI, indépendant de la distribution hôte. L'ISO est un artefact de CI
(≈ 3 Go) et non un fichier du dépôt. Les composants Plasma provisoires seront remplacés par les modules VinX.
