# ADR 0014 — Gestionnaire de fichiers « Fichiers »

- **Statut** : accepté
- **Date** : 2026-11-15

## Contexte

Le gestionnaire de fichiers est l'application la plus utilisée après le navigateur. Options étudiées :
créer de zéro, forker un existant (Dolphin, Nautilus), Dolphin thémé, ou une interface VinX sur
les bibliothèques KDE.

## Décision

**Interface VinX (Qt/QML) sur le moteur KIO de KDE** (`vinx-files`, `shell/apps/files`).

- `FolderModel` : contenu d'un dossier via `KCoreDirLister` (local, corbeille, réseau, MTP…).
- `FileOps` : copier, déplacer, corbeille, restaurer, supprimer, renommer, ouvrir via les jobs KIO
  (conflits de noms, progression, « Ouvrir avec » gérés par les dialogues KIO).
- Sans KIO à la compilation (poste de développement), un moteur local Qt (QDir, QFile,
  `QFile::moveToTrash`) prend le relais ; il est couvert par `tst_files`.
- Dolphin reste installé pour les usages avancés (renommage en masse, onglets, comparaison).

## Pourquoi pas un fork ou une création de zéro

- **De zéro** : copies avec reprise, corbeille freedesktop, réseau (SMB, SFTP), MTP, miniatures,
  conflits… des mois de travail et un risque de perte de données.
- **Fork** : maintenance seul d'environ 100 000 lignes, sans liberté d'interface.
- **Hybride** : quelques milliers de lignes à nous, la partie risquée reste maintenue par KDE et Debian.

## Conséquences

- Dépendances : `libkf6kio-dev` (construction), `kio-extras` (recommandé : miniatures, réseau).
- Fichiers devient l'application par défaut des dossiers (`mimeapps.list` de la session VinX)
  et remplace Dolphin dans le dock.
