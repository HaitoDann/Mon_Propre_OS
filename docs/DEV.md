# Faire évoluer VinX OS depuis VinX OS

VinX peut être utilisé au quotidien tout en étant modifié : l'interface (barre, dock, panneaux,
Paramètres, Store, Fichiers, thème, icônes) est entièrement dans le paquet `vinx-shell`.
Aucune ISO n'est nécessaire pour la faire évoluer.

## La commande `vinx-dev`

| Commande | Effet |
|---|---|
| `vinx-dev` | Récupère les modifications (`git pull`), reconstruit, installe et relance le shell. |
| `vinx-dev build` | Reconstruit sans installer. |
| `vinx-dev install` | Installe la dernière version construite. |
| `vinx-dev rollback` | Revient à la version construite précédente (un second appel y retourne). |
| `vinx-dev restart` | Relance le shell sans fermer la session ni les applications. |
| `vinx-dev preview` | Ouvre le bureau VinX dans une fenêtre de test, la session reste intacte. |
| `vinx-dev status` | Version installée, branche, versions gardées. |
| `vinx-dev log` | Journal du shell (plantages, erreurs). |

Options : `--no-pull` (travailler sur ses modifications locales sans récupérer), `--repo CHEMIN`.
Par défaut le dépôt est `~/Mon_Propre_OS` et les 5 dernières versions construites sont gardées
dans `~/.cache/vinx-dev/builds`. Le journal de construction est `~/Mon_Propre_OS/.vinx-dev-build.log`.

La première fois, `vinx-dev` installe les outils de construction (mot de passe administrateur).

## Filets de sécurité

1. `vinx-dev rollback` : version précédente du shell.
2. Instantanés du système (Paramètres → Sauvegarde) : retour arrière complet.
3. Session « Plasma » sur l'écran de connexion (bouton « Session ») si le shell ne démarre plus.
4. Relance automatique du shell en cas de plantage (5 fois au plus en 2 minutes).
5. Terminal de secours : Ctrl + Alt + F3.
6. Clé USB VinX : démarrage et réparation en dernier recours.

## Ce que `vinx-dev` ne met pas à jour

Les réglages système fournis par l'ISO (paquets installés, écran de démarrage Plymouth, thèmes
KDE et GTK, installateur) : ils changent à la prochaine installation, ou se copient à la main
depuis `distro/live/config/includes.chroot`.
