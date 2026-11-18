# ADR 0031 — Mises à jour sans risque : instantanés et btrfs par défaut

- **Statut** : accepté
- **Date** : 2026-11-18

## Contexte

Les instantanés Timeshift existaient (`vinx-snapshots`, un instantané par jour avant les mises à
jour via le crochet APT `80vinx-snapshot`) mais restaient invisibles : pas de liste, pas de retour
arrière simple, activation manuelle. Validé par l'utilisateur : btrfs par défaut, aucun choix
technique à l'écran de bienvenue.

## Décision

- **« Mises à jour » → Instantanés** : interrupteur, « Créer maintenant », liste des états
  enregistrés (date, motif), « Revenir à cet état… » avec confirmation sur place (documents non
  touchés), puis « Redémarrer maintenant ». Actions administrateur par
  `pkexec /usr/lib/vinx/vinx-snapshots enable|disable|create|restore NOM` ; la liste est publiée par
  le script dans `/var/lib/vinx/snapshots.list` (lisible sans droits ; analyse testée
  `parseTimeshiftList`).
- **Installateur en btrfs par défaut** (ext4 et xfs restent proposés), sous-volumes `@`, `@home`,
  `@cache`, `@log` (Timeshift exige `@` et `@home`), fichier d'échange dans `@swap`.
- **Activation automatique** sur btrfs : service `vinx-snapshots-firstboot` (une fois, hors live),
  premier instantané immédiat. En ext4 (copie complète par rsync, plusieurs Go), rien n'est activé
  d'office : l'utilisateur choisit dans « Mises à jour ».
- **Menu de démarrage** : `grub-btrfs` (crochet ISO, facultatif si le paquet manque) avec
  `grub-btrfsd --timeshift-auto` ; sous-menu « VinX OS — revenir à un état précédent ».

## Conséquences

- Les installations existantes en ext4 (portable de l'utilisateur) gardent le retour arrière depuis
  « Mises à jour », pas l'entrée du menu de démarrage.
- Non vérifié ici : Timeshift, btrfs, grub-btrfs et l'installateur ne se testent que sur une vraie
  installation (nom du paquet `grub-btrfs` à confirmer à la construction de l'ISO).
