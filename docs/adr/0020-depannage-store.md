# ADR 0020 — Assistant de dépannage et Store enrichi

- **Statut** : accepté
- **Date** : 2026-11-17

## Assistant de dépannage (Paramètres → Dépannage)

- Lit le journal depuis le démarrage (système et session), l'espace disque (`df`) et l'accès à
  Internet (`nmcli networking connectivity`).
- Règles de traduction dans `diagparse.h` (testées) : imprimante injoignable, Wi-Fi refusé ou
  instable, micrologiciel manquant, erreurs disque, mémoire saturée, Bluetooth, carte graphique,
  son, service en échec, redémarrage du bureau, disque plein, portail de connexion, hors ligne.
- Chaque problème : gravité, explication en français courant, action (ouvre la bonne page).
- Si le journal système n'est pas lisible sans droits, « Analyse complète » passe par
  `vinx-admin journal` (pkexec). Le détail technique reste consultable pour une demande d'aide.

## Store

- **Recherche dans le dépôt Debian** (en plus de Flathub) : composants AppStream (nom, résumé,
  icône), outils techniques en option (`apt-cache search`), état installé, installation et
  suppression via PackageKit avec progression.
- **Fiche détaillée** (Flathub et Debian) : description (en français si disponible), version,
  licence, tailles, site ou page Flathub.
- **Mises à jour en arrière-plan** : `/usr/lib/vinx/vinx-update` est lancé détaché et écrit son
  état dans `$XDG_RUNTIME_DIR/vinx-update.json` ; le Store et la barre supérieure en affichent
  la progression en direct, l'installation continue si le Store est fermé, une notification
  annonce la fin. Option : mise à jour automatique des applications Flathub (sans mot de passe).
- `vinx-store --search TEXTE` (préfixe `debian:` pour le dépôt Debian).
