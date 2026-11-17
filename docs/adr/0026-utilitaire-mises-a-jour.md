# ADR 0026 — Utilitaire « Mises à jour »

- **Statut** : accepté
- **Date** : 2026-11-17

## Décision

- Application dédiée `vinx-updates` (« Mises à jour ») qui remplace les mises à jour de Discover et
  regroupe ce que montraient le Store et les Paramètres :
  - **Vue d'ensemble** : version de VinX OS (`/etc/vinx-release`), bureau VinX, Debian, noyau ;
    état ; « Tout mettre à jour » ; mises à jour groupées (bureau VinX — paquets `vinx-*` —,
    système Debian, applications Flathub).
  - **Historique** : journal d'APT (`/var/log/apt/history.log`, analyse testée `parseAptHistory`).
  - **Réglages** : recherche automatique, mise à jour automatique des applications.
- L'installation reste celle de `/usr/lib/vinx/vinx-update` (arrière-plan, PackageKit, Flatpak).
- Points d'entrée : barre supérieure (indicateur d'installation), notifications, Paramètres →
  Mises à jour et À propos.

## Conséquences

- Instantané automatique avant mise à jour : pas encore (prévu avec le retour arrière depuis le
  menu de démarrage).
- Les mises à jour du bureau VinX par APT dépendent du dépôt APT VinX (clé et GitHub Pages à
  activer, docs/APT.md) ; d'ici là, `vinx-dev`.
