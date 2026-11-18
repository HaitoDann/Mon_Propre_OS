# ADR 0030 — Bienvenue simplifiée et réglages « Avancé… » remplacés

- **Statut** : accepté
- **Date** : 2026-11-18

## Bienvenue (4 étapes)

Bienvenue, Internet (liste Wi-Fi intégrée), Apparence (clair/sombre, accent), Gestes essentiels (+ Store).
Aucun réglage technique pour un débutant : **instantanés activés automatiquement** (ADR 0031) et
**format Microsoft Office par défaut** (ADR 0029). L'étape « comptes en ligne » (module KDE) est retirée.

## Boutons « Avancé… » des Paramètres

| Où | Décision |
|---|---|
| Bureau → bureaux virtuels | Remplacé : nombre (1 à 6) et noms dans la page (libtaskmanager + D-Bus KWin `setDesktopName`) |
| Écrans | Remplacé : fréquence de rafraîchissement et orientation (`kscreen-doctor`) ; le bouton disparaît |
| Réseau | Réduit : VPN (import WireGuard / OpenVPN, connexion, suppression) et adresse IP fixe (`nmcli`, analyses testées) ; « Avancé… » reste pour 802.1X, proxy et cas particuliers |
| Imprimantes | Remplacé : format du papier, recto verso, couleur (`lpoptions`, par utilisateur) ; l'ajout manuel d'une vieille imprimante passe par la page d'administration CUPS (navigateur) |
| Utilisateurs → comptes en ligne | Gardé pour l'instant (module KDE) |

Dépendances : `qml6-module-qtquick-dialogs` (sélecteur de fichier), `network-manager-openvpn` (recommandé).
