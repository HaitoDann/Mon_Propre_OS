# ADR 0013 — Dépôt APT et préparation à l'installation

- **Statut** : accepté
- **Date** : 2026-11-15

## Contexte

Pour un usage quotidien, les corrections du shell doivent arriver sans réinstaller.
L'installateur doit produire un système utilisable sur du matériel réel.

## Décision

- **Dépôt APT signé** sur GitHub Pages, construit par `distro/scripts/make-apt-repo.sh`
  (apt-ftparchive, signature GPG ed25519) et publié par le workflow `apt-repo.yml`
  uniquement sur étiquette `shell-v*` (économie de minutes Actions).
- La clé privée vit seulement dans le secret GitHub et une sauvegarde hors ligne.
- L'ISO intègre la source `vinx.sources` (format deb822, `Signed-By`) si la clé publique existe ;
  les mises à jour passent par PackageKit, donc par le Store.
- Calamares : réglages de `calamares-settings-debian` modifiés clé par clé (hook 0920) :
  ext4, chiffrement LUKS proposé, fichier d'échange, EFI 512 Mio, pas de mot de passe root
  (sudo), session VinX par défaut. Paquets shim-signed / grub-efi-amd64-signed (Secure Boot),
  micrologiciels supplémentaires, microcode, fwupd.

## Conséquences

- Publier = augmenter la version du changelog + pousser une étiquette.
- GitHub Pages impose un dépôt public (ou un abonnement payant).
- Passer plus tard à un hébergement dédié ne demande que de changer `VINX_APT_URL`.
