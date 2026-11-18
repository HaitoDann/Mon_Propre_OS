# ADR 0035 — Moniteur système VinX

- **Statut** : accepté
- **Date** : 2026-11-18

## Contexte

Le moniteur de KDE (plasma-systemmonitor) montre des centaines de processus et des tableaux de bord
configurables : trop technique pour savoir « qui ralentit mon ordinateur » et fermer une application
bloquée. Maquette retenue : proposition A (liste dense), sans jauge de batterie ni phrase d'explication.

## Décision

`vinx-monitor` (`shell/apps/monitor`), ouvert par **Ctrl+Échap** (raccourci global écrit par `vinx-session`)
ou par la recherche ; le moniteur de KDE est masqué (`Hidden=true`, comme ADR 0025).

- **Bandeau** de quatre mini-graphiques sur 2 minutes : processeur, mémoire, disque (lecture / écriture),
  réseau (↓ / ↑). Un clic trie la liste par cette ressource.
- **Une seule liste par application**, dépliable en processus ; colonnes processeur (en % de la machine),
  mémoire (PSS : la mémoire partagée n'est comptée qu'une fois), disque (lecture + écriture). Les valeurs
  notables se colorent en ambre, les fortes en ambre foncé. « Services du système » toujours en dernier.
- **Regroupement** : unité systemd d'application (`app-<id>-<aléa>.scope`, convention XDG), sinon premier
  ancêtre lancé par la session (navigateur pour ses onglets, terminal pour son shell), relié à son `.desktop`
  par le programme de `Exec`. Tout le reste (autres utilisateurs, services du bureau) va dans
  « Services du système ».
- **Actions** (seulement sur les processus de l'utilisateur) : Fermer (SIGTERM ; si l'application est encore
  là 4 s plus tard, bandeau « ne répond plus » → Forcer la fermeture), Forcer (SIGKILL), copier le numéro ou
  la commande, ouvrir l'emplacement du programme, priorité basse. Suppr / Maj+Suppr, Ctrl+F, flèches.
- Lecture directe de `/proc` (`procparse.h`, testé), toutes les 2 s ; mise à jour de la liste par
  déplacements de lignes (la vue ne saute pas).

## Conséquences

- Pas de réseau par application (demanderait les droits administrateur ou eBPF).
- Les processus du système (root) ne peuvent pas être fermés d'ici : c'est voulu.
- `VINX_PROC_ROOT` / `VINX_PROC_UID` permettent de tester sur un faux `/proc`.
- Non vérifié ici : le raccourci Ctrl+Échap et les vraies unités systemd des applications sous KDE.
