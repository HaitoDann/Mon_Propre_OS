# ADR 0043 — Icônes VinX pour les utilitaires installés par défaut

- **Statut** : accepté
- **Date** : 2026-11-20

## Contexte

Le thème d'icônes VinX (ADR 0018) couvre les applications VinX, les emplacements et les types de fichiers.
Les utilitaires KDE et Debian installés par défaut (Ark, KCalc, Okular, Timeshift, installateur,
imprimantes, portefeuille KDE) affichaient leur icône Breeze, d'un autre style. « Mises à jour »
utilisait le logo VinX.

## Décision

- Ces utilitaires reçoivent une tuile VinX (tuile neutre, pictogramme au trait, point de couleur) :
  `ark`, `accessories-calculator`, `okular`, `timeshift`, `install-debian`/`calamares`,
  `printer`, `kwalletmanager` (et leurs identifiants `org.kde.*`).
- « Mises à jour » a sa propre icône `org.vinx.updates`.
- Les logiciels tiers à marque forte (Firefox, Thunderbird, LibreOffice, VLC) gardent leur logo officiel.
- Nouveaux pictogrammes : `archive`, `calculator`, `history`, `install`, `update`.
