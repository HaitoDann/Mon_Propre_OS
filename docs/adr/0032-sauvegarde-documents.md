# ADR 0032 — Sauvegarde des documents

- **Statut** : accepté
- **Date** : 2026-11-18

## Décision

- Outil minimaliste `vinx-backup` (script, testé par `tests/backup-test.sh`) : copie des dossiers
  choisis (Documents, Images, Bureau par défaut ; Musique, Vidéos, Téléchargements en option) sur un
  disque externe, dans `VinX-Sauvegarde/<utilisateur>/<AAAA-MM-JJ>/`.
- **Une version par jour**, **30 versions gardées** ; `rsync --link-dest` : les fichiers inchangés sont
  des liens physiques vers la version précédente (pas de place en plus).
- **Automatique** : minuteur utilisateur horaire (`vinx-backup.timer`, démarré par `vinx-session`) qui
  sauvegarde si la dernière sauvegarde a plus de 24 h **et** si le disque est branché ; notification à
  la fin.
- **Restauration sans risque** : une version est copiée dans « ~/Restauration du AAAA-MM-JJ », ouverte
  dans Fichiers ; les fichiers actuels ne sont jamais écrasés.
- Interface : Paramètres → Sauvegarde (disque, automatique, dossiers en pastilles, « Sauvegarder
  maintenant », versions). Réglages dans le groupe `[backup]` de `shell.ini`.

## Conséquences

- Le disque doit être formaté en ext4, btrfs ou NTFS récent (liens physiques) ; en FAT/exFAT, chaque
  version est une copie complète (non optimisé).
- Pas de sauvegarde en ligne pour l'instant.
