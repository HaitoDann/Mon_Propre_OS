# Recette 1.0 — à dérouler sur le portable

But : vérifier sur du **vrai matériel** tout ce qui n'a été testé qu'en simulation (ADR 0039).
Pour chaque ligne : ✅ fonctionne, ❌ bogue (noter ce qui se passe), ➖ non testable (pas le matériel).

Avant de commencer : ISO neuve (`sudo ./distro/build.sh`), installation **en btrfs**, puis
`vinx-dev rapport` une première fois (captures de toutes les pages + journaux, voir [DEV.md](DEV.md)).
Envoyer l'archive ou les captures à Claude avec la liste des ❌.

## 1. Installation et démarrage

| # | Test | Attendu | État |
|---|---|---|---|
| 1.1 | Démarrer la clé USB (UEFI, Secure Boot activé) | Menu GRUB aux couleurs VinX, Plymouth VinX | |
| 1.2 | Installer avec chiffrement, système de fichiers btrfs | Installation sans erreur, redémarrage | |
| 1.3 | Premier démarrage | Saisie du mot de passe de chiffrement VinX, écran de connexion VinX | |
| 1.4 | Ouverture de session | Bureau VinX, Bienvenue s'ouvre | |
| 1.5 | Menu de démarrage | Entrée « revenir à un état précédent » présente (après un instantané) | |

## 2. Bureau

| # | Test | Attendu | État |
|---|---|---|---|
| 2.1 | Barre, dock, recherche (Méta), vue d'ensemble | Réactifs, pas de clignotement | |
| 2.2 | Centre de contrôle : Wi-Fi, son, luminosité, Bluetooth | Les réglages agissent vraiment | |
| 2.3 | Notifications (ex. clé USB branchée) | Bulle VinX, historique | |
| 2.4 | Menu global d'une application KDE et d'une application GTK | Menus dans la barre | |
| 2.5 | Verrouillage (Méta+L), mise en veille, réveil | Écran VinX, retour au bureau | |
| 2.6 | Extinction / redémarrage / déconnexion | Fenêtre VinX, action effective | |
| 2.7 | Capture (Méta+Maj+S, Impr. écran), presse-papiers (Méta+V) | Capture copiée, historique | |
| 2.8 | Écran externe branché | Bulle de branchement, choix appliqué | |
| 2.9 | Fenêtre de mot de passe administrateur (polkit) | Fenêtre VinX, pas celle de KDE | |

## 3. Paramètres

| # | Page | Test | État |
|---|---|---|---|
| 3.1 | Wi-Fi / Réseau | Lister, se connecter (WPA2, réseau caché), IP fixe | |
| 3.2 | Écrans | Résolution, échelle, disposition, mode nuit | |
| 3.3 | Son | Sortie/entrée, casque Bluetooth | |
| 3.4 | Énergie | Batterie, profils, veille | |
| 3.5 | Imprimantes | Détection et ajout d'une imprimante réseau/USB, page de test | |
| 3.6 | Pilotes | Détection (Wi-Fi, NVIDIA s'il y a lieu), installation | |
| 3.7 | Utilisateurs | Créer, modifier, supprimer un compte | |
| 3.8 | Sauvegarde | Instantané manuel, instantanés automatiques, sauvegarde des documents | |
| 3.9 | Dépannage | Diagnostics justes, réparations proposées | |
| 3.10 | Mises à jour | Vérification en arrière-plan, installation | |
| 3.11 | Apparence | Clair/sombre, 8 accents + Automatique, fond « VinX Logo » | |
| 3.12 | Clavier, accessibilité, date et heure | Réglages appliqués | |
| 3.13 | Anglais | Langue anglaise : aucun texte français restant | |

## 4. Applications

| # | Application | Test | État |
|---|---|---|---|
| 4.1 | Store | Recherche Flathub et Debian (`gimp`), fiche détaillée, installer/désinstaller | |
| 4.2 | Store / Mises à jour | Mise à jour de `vinx-shell` **via le dépôt APT** | |
| 4.3 | Fichiers | Onglets, glisser-déposer, conflits, réseau (SMB), corbeille | |
| 4.4 | Terminal | Ouverture, onglets, copier/coller | |
| 4.5 | Images | Ouvrir, diaporama, Modifier, enregistrer | |
| 4.6 | Moniteur (Ctrl+Échap) | Processus, arrêt d'un processus | |
| 4.7 | Bureautique | Ouvrir/enregistrer un .docx et un .odt | |

## 5. Système

| # | Test | Attendu | État |
|---|---|---|---|
| 5.1 | Retour arrière : démarrer sur un instantané | Système dans l'état précédent | |
| 5.2 | Plantage du shell (`pkill vinx-shell`) | Relance automatique | |
| 5.3 | Autonomie (1 h d'usage bureautique) | Comparable à une autre distribution | |
| 5.4 | Usage d'une semaine | Noter les gênes, lenteurs, incohérences | |

## Problèmes connus acceptés pour la 1.0

(à remplir pendant la recette)
