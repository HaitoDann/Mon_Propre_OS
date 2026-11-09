# ADR 0003-store-flatpak-apt — Store basé sur Flatpak + APT

- **Statut** : accepté
- **Date** : 2026-11-09

## Contexte
Le store doit installer des applications et des « packs » sans fragiliser la base stable.

## Décision
Applications via Flatpak (Flathub et dépôt maison possible) ; packs système via APT. Backend : libflatpak et PackageKit.

## Conséquences
Applications isolées et à jour ; on ne développe pas de gestionnaire de paquets.
