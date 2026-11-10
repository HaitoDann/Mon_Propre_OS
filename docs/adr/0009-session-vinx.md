# ADR 0009 — Session « VinX OS » et dock

- **Statut** : accepté
- **Date** : 2026-11-10

## Contexte
Le shell natif (barre, dock) doit remplacer l'interface de Plasma sans perdre ce que fournit
la session Plasma : KWin, services (kded, énergie, Bluetooth, polkit), portails XDG, raccourcis globaux.
Le dock a besoin de la liste des fenêtres de KWin.

## Décision
- **Session** `vinx.desktop` (Wayland) : lance `startplasma-wayland` avec `VINX_SESSION=1`.
  - Un *drop-in* systemd ajoute à `plasma-plasmashell.service` une condition `ExecCondition` :
    plasmashell ne démarre pas en session VinX.
  - `vinx-shell` démarre par l'autostart XDG, uniquement si `VINX_SESSION=1`.
- **Surfaces layer-shell** de `vinx-shell` : fond d'écran (couche *background*), dock et barre (couche *top*,
  zones réservées), couche des panneaux (*overlay*, plein écran, visible seulement à l'ouverture d'un menu).
- **Tâches** : gestionnaire de tâches de KDE (`org.kde.taskmanager`, libtaskmanager) chargé dynamiquement ;
  à défaut (développement, tests), un modèle d'aperçu exposant les mêmes rôles.
- **Icônes du dock** : pictogrammes VinX pour les applications connues ; icône du thème système sinon.
- La session Plasma reste la session par défaut ; « VinX OS (expérimental) » est proposée à l'écran de connexion.

## Conséquences
Pas de réimplémentation des services de session ni de la gestion des fenêtres. Sans plasmashell, il manque
temporairement le serveur de notifications (étape 6) et le multi-écran (barre et dock sur l'écran principal).
La validation finale se fait sur l'ISO, dans la session « VinX OS (expérimental) ».
