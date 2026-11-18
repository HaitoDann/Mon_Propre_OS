# ADR 0039 — Consolidation et gel des fonctions pour la 1.0

- **Statut** : accepté
- **Date** : 2026-11-18

## Contexte

VinX dispose de toutes les briques prévues (shell, Paramètres, Store, Fichiers, outils, ISO btrfs,
traduction anglaise), mais une grande partie n'a jamais été éprouvée sur du matériel réel. Publier une
1.0 demande de la stabilité plutôt que de nouvelles fonctions.

## Décision

- **Gel des fonctions** : jusqu'à la 1.0, on n'ajoute plus de fonction ; seulement corrections,
  finitions, traduction, documentation et publication.
- **Hors 1.0** (documentés comme « après 1.0 ») : comptes en ligne, réseau expert (802.1X, proxy),
  lecteur PDF, autres langues que français et anglais, arm64.
- **Critère de sortie** : chaque ligne de `docs/RECETTE.md` est ✅ ou acceptée comme problème connu
  dans les notes de version ; CI verte ; ISO neuve installée et mise à jour par le dépôt APT.
- **Branches** : `main` devient la branche principale (état publiable) ; le travail se fait sur des
  branches de travail fusionnées dans `main`. Les correctifs 1.0.x partent de l'étiquette `shell-v1.0.0`.
- **Nettoyage** : dossiers vides d'origine, maquette web (ancienne charte violette) et ses captures
  retirés du dépôt (toujours dans l'historique git).

## Conséquences

Les demandes de nouvelles fonctions sont notées dans `docs/ROADMAP.md` (« Après 1.0 ») au lieu d'être
réalisées tout de suite. La recette sur le portable devient le chemin critique.
