# ADR 0005-monorepo — Monorepo

- **Statut** : accepté
- **Date** : 2026-11-09

## Contexte
Le projet compte plusieurs modules fortement liés (branding, shell, apps, distro).

## Décision
Un seul dépôt ; un dossier par module, chacun avec son paquet .deb.

## Conséquences
Modifications transverses atomiques, CI unique. Il faut garder des frontières de modules nettes.
