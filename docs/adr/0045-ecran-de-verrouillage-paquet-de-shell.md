# ADR 0045 — Écran de verrouillage : paquet de shell Plasma

- **Statut** : accepté
- **Date** : 2026-11-20

## Contexte

Sur le portable, le verrouillage (Méta+L, capot) affichait l'écran Breeze de KDE, alors que
`LockScreen.qml` était bien installé dans le paquet d'apparence `org.vinx.desktop` et que
`LookAndFeelPackage` le désignait. Même un écran de test minimal y était ignoré.

Le code de kscreenlocker 6.3 (Debian 13) montre pourquoi : `UnlockApp::setShell()` charge l'écran
dans un paquet **Plasma/Shell** (`lockscreenmainscript` = `contents/lockscreen/LockScreen.qml`), choisi par
`plasmashellrc [Shell] ShellPackage`, sinon `$PLASMA_DEFAULT_SHELL`, sinon `org.kde.plasma.desktop`
(`settings/shell_integration.cpp`, `defaultShell()`). Le paquet d'apparence n'est plus consulté.

## Décision

- vinx-shell installe un paquet de shell **réduit** `org.vinx.lockscreen` dans `/usr/share/plasma/shells/` :
  `metadata.json` (`Plasma/Shell`, `X-Plasma-APIVersion` 2, exigé par `verifyPackageApi`),
  `contents/lockscreen/LockScreen.qml` (l'écran VinX) et `contents/views/Desktop.qml`, vide (fichier exigé
  par la structure, jamais chargé).
- `vinx-session` exporte `PLASMA_DEFAULT_SHELL=org.vinx.lockscreen`, transmis à KWin et à kscreenlocker
  par l'environnement de la session. plasmashell ne démarre pas en session VinX (ADR 0009), donc ce paquet
  n'est jamais utilisé comme bureau.
- Si `plasmashellrc` contient `ShellPackage=org.kde.plasma.desktop` (valeur par défaut, qui passerait avant
  la variable), la session VinX la retire. Toute autre valeur choisie par l'utilisateur est respectée.
- `LockScreen.qml` ne dépend plus de `Vinx.Shell` (fond et apparence lus directement), pour rester léger dans
  le processus de verrouillage.
- La session Plasma (sans la variable) garde l'écran Breeze.

## Conséquences

- L'ancienne copie dans le paquet d'apparence reste installée, pour les versions de Plasma qui la lisent.
- À vérifier sur le portable après mise à jour : test sans se déconnecter avec
  `PLASMA_DEFAULT_SHELL=org.vinx.lockscreen kscreenlocker_greet --testing`, puis Méta+L après reconnexion.
