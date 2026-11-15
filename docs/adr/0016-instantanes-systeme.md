# ADR 0016 — Instantanés du système et compléments du quotidien

- **Statut** : accepté
- **Date** : 2026-11-15

## Décision

- **Instantanés** : Timeshift (mode rsync sur ext4, btrfs si la racine l'est), piloté par
  `/usr/lib/vinx/vinx-snapshots` (pkexec, action polkit `org.vinx.snapshots`).
  Instantané quotidien et avant toute installation APT (`DPkg::Pre-Invoke`, une fois par jour).
  Les dossiers personnels sont exclus : ce n'est pas une sauvegarde des documents.
- **Paramètres natifs** reposant sur les outils KDE et freedesktop existants :
  Écrans (`kscreen-doctor`), Énergie (`powerdevilrc` + `powerprofilesctl`), Imprimantes (CUPS),
  Utilisateurs et comptes en ligne (modules KDE pour les réglages avancés).
- **Premier démarrage** : apparence, réseau, comptes en ligne, instantanés, Store, raccourcis.

## Conséquences

- Paquets : timeshift, rsync, cups, print-manager, power-profiles-daemon.
- Les clés `powerdevilrc` (Plasma 6) sont à surveiller lors des mises à jour de Plasma.
