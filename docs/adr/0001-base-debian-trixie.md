# ADR 0001-base-debian-trixie — Base Debian 13 Trixie + Wayland

- **Statut** : accepté
- **Date** : 2026-11-09

## Contexte
Il faut une base stable, maintenue et compatible avec le matériel courant.

## Décision
Debian 13 « Trixie » stable, amd64, session Wayland uniquement.

## Conséquences
Cycle de 2 ans, paquets éprouvés. Pas de session X11 : les applications X passent par XWayland.
