# ADR 0010 — Applications système, Store et préférences partagées

- **Statut** : accepté
- **Date** : 2026-11-10

## Contexte
Il faut une première version des Paramètres, du Store et d'un assistant de premier démarrage,
cohérents avec le shell et réglables sans redémarrer la session.

## Décision
- **Préférences partagées** : un fichier `~/.config/vinx/shell.ini` (QSettings), surveillé par tous les
  processus (`Preferences.revision`). Le shell applique apparence, fond d'écran, widgets, dock et
  Ne pas déranger dès qu'un autre processus les modifie.
- **Applications** `vinx-settings`, `vinx-store`, `vinx-welcome` : mêmes modules QML que le shell,
  démarrage commun (`apps/appmain.h`).
- **Store** : catalogue de packs thématiques (`apps/store/Catalog.js`) d'applications **Flathub**,
  installées avec `flatpak --user` : pas de mot de passe administrateur, pas de risque pour le système de base.
  Les paquets Debian (APT/PackageKit) seront ajoutés plus tard pour les composants système.
- **Réglages avancés** (écrans, réseau, imprimantes, comptes) : délégués aux Paramètres système de KDE.
- **Premier démarrage** : `vinx-shell` lance `vinx-welcome` tant que `welcome/done` n'est pas vrai.

## Conséquences
Réglages immédiats et cohérents entre le shell et les applications. Le Store dépend de l'accès à Flathub ;
les pages avancées gardent l'apparence KDE (palette VinX) en attendant des pages natives.
