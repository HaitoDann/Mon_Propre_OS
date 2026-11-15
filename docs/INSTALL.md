# Installer VinX OS sur un ordinateur

## Avant de commencer

- **Sauvegarde tes données** : l'installation peut effacer le disque.
- Matériel : processeur 64 bits (amd64), 4 Go de mémoire (2 Go minimum), 25 Go de disque.
- Une clé USB d'au moins 4 Go.

## 1. Créer la clé USB

Sous Linux (remplace `/dev/sdX` par ta clé : `lsblk` pour la trouver — attention à ne pas
te tromper de disque) :

```bash
sudo dd if=vinx-os-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Sous Windows : [Rufus](https://rufus.ie) en mode « DD ». Partout : [Ventoy](https://ventoy.net) ou balenaEtcher.

## 2. Démarrer sur la clé

- Au démarrage, touche du menu de démarrage (souvent F12, F11, Échap ou F8) puis choisir la clé.
- **UEFI** recommandé. Le **Secure Boot** peut rester activé sur le système installé
  (chargeur signé Debian). Si la clé ne démarre pas, désactive-le le temps de l'installation.
- Le système démarre en mode « live » : tu peux tout essayer sans rien modifier.

## 3. Vérifier le matériel en live

Avant d'installer, contrôle : Wi-Fi, son (centre de contrôle), écrans, veille (menu système),
pavé tactile, webcam. Note ce qui ne marche pas et signale-le.

## 4. Installer

Icône **« Installer VinX OS »**, puis :

| Étape | Conseil |
|---|---|
| Langue, fuseau, clavier | Français, Europe/Paris, Français (azerty) |
| Partitions | **Effacer le disque** pour un poste dédié ; **Installer à côté** pour garder Windows. Coche **Chiffrer le système** sur un portable. |
| Utilisateur | Ton compte est administrateur ; son mot de passe sert aussi pour les mises à jour. |

Système de fichiers par défaut : ext4, avec un fichier d'échange et une partition EFI de 512 Mio.

## 5. Après l'installation

- Le Store → Mises à jour : installe les mises à jour proposées.
- Paramètres → Réseau, Son, Date et heure : vérifie les réglages.
- Mises à jour du micrologiciel (BIOS, SSD…) : `fwupdmgr refresh && fwupdmgr update`.

## Problèmes connus

- **Carte NVIDIA** : le pilote libre (nouveau) est utilisé par défaut. Le pilote propriétaire
  nécessite la section `non-free` de Debian : `sudo apt install nvidia-driver` après l'avoir activée.
- **Double démarrage avec Windows** : désactive le « démarrage rapide » de Windows avant d'installer.
