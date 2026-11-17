# ADR 0025 — Terminal VinX et applications KDE remplacées

- **Statut** : accepté (lot 1 de « VinX sans interfaces KDE »)
- **Date** : 2026-11-17

## Contexte

L'utilisateur veut décharger VinX des interfaces KDE visibles. KWin et les bibliothèques KDE restent
dessous (réécrire un compositeur n'est ni réaliste ni souhaitable pour la stabilité). Lot 1 validé :
terminal, fenêtres (ADR 0024), mises à jour (ADR 0026), masquage de Dolphin, Discover et de la
Configuration du système.

## Décision

- **Terminal VinX** (`vinx-terminal`, `shell/apps/terminal`) : Qt Widgets + **QTermWidget**
  (moteur de terminal de LXQt, sans dépendance KDE ; paquet de développement QTermWidget Qt 6 de Debian, nom à confirmer).
  Onglets (Ctrl+Maj+T/W, Ctrl+PgPréc/PgSuiv), copier/coller (Ctrl+Maj+C/V), recherche
  (Ctrl+Maj+F), zoom, menu contextuel en français, liens cliquables, `--workdir` et `-e`.
  Couleurs VinX (schémas clair et sombre générés, `termtheme.h` testé), police **IBM Plex Mono**
  fournie (SIL OFL), suit les préférences VinX en direct (accent, thème ; « auto » via
  `appearance/resolvedAccent` écrit par le shell).
- Couleurs VinX pour le C++ : `gen_theme.py` écrit aussi `vinxtokens.h` (cible `vinx::tokens`).
- **Masquage sans désinstaller** : la session VinX place `/usr/share/vinx/data` en tête de
  `XDG_DATA_DIRS`, avec des entrées `Hidden=true` pour Konsole, Dolphin, Discover, Configuration
  du système et Centre d'informations. Les autres sessions (Plasma) ne sont pas touchées.
- Terminal par défaut : `kdeglobals` de la session (`TerminalApplication=vinx-terminal`) ;
  Fichiers ouvre le Terminal VinX ; les épinglages du dock suivent (Konsole → Terminal, etc.).
- ISO : Dolphin et Discover retirés de la liste des paquets ; Konsole reste installé en secours.

## Conséquences

- Le Terminal VinX est **facultatif à la construction** : sans QTermWidget, il n'est pas construit et
  Konsole n'est ni masqué ni remplacé (le masquage et `kdeglobals` ne s'installent qu'avec lui).

- Les boutons « Avancé… » des Paramètres ouvrent encore des modules KDE (lot 2).
- Le Terminal ne se compile qu'en CI Debian 13 (QTermWidget Qt 6 absent de l'environnement local).
