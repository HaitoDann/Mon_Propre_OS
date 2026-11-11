# ADR 0011 — Écran de verrouillage VinX sur kscreenlocker

- **Statut** : accepté
- **Date** : 2026-11-11

## Contexte
L'écran de verrouillage est l'écran le plus vu après le bureau. C'est aussi un composant de sécurité :
une erreur peut laisser une session accessible ou enfermer l'utilisateur dehors.

## Décision
- On garde **kscreenlocker** (KDE) : verrouillage géré par KWin, authentification PAM, protection
  contre la fermeture de l'écran sans authentification réussie.
- On fournit seulement **l'interface** : `contents/lockscreen/LockScreen.qml` du paquet d'apparence
  `org.vinx.desktop`, construit avec les composants VinX (installé par le paquet `vinx-shell`).
- Interface utilisée (version 2 de kscreenlocker) : `authenticator` (`startAuthenticating`, `respond`,
  signaux `promptForSecretChanged`, `succeeded`, `failed`), `kscreenlocker_userName`, propriétés `locked`,
  `suspendToRamSupported` et signal `suspendToRam`.
- Si notre QML ne se charge pas, kscreenlocker affiche automatiquement son écran de secours.

## Conséquences
Identité VinX sans réimplémenter la sécurité. Un banc de test (`tests/tst_lockscreen.cpp`) simule
l'authentificateur et vérifie : chargement sans erreur, refus d'un mauvais mot de passe, déverrouillage
uniquement après succès. Le changement d'utilisateur depuis l'écran de verrouillage reste à ajouter.
