# Architecture

## Principe
On réutilise le bas niveau éprouvé (noyau, systemd, Mesa, PipeWire, NetworkManager, BlueZ, UPower, xdg-desktop-portal)
et on développe sur mesure **uniquement la couche visible** : shell, applications système, store, branding.

## Couches
```
┌──────────────────────────────────────────────┐
│ Apps système (Paramètres, Store) — Qt6/QML   │
│ Shell (barre, dock, lanceur, notifs) — QML   │
│ Design system QML  ← tokens générés (branding)│
├──────────────────────────────────────────────┤
│ KWin (compositeur Wayland)                   │
├──────────────────────────────────────────────┤
│ Services via D-Bus : NetworkManager, PipeWire,│
│ UPower, BlueZ, PackageKit, libflatpak, portals│
├──────────────────────────────────────────────┤
│ Debian 13 Trixie — systemd — noyau Linux     │
└──────────────────────────────────────────────┘
```

## Règles
- Chaque module produit son paquet `.deb`, a ses tests et son README.
- Les modules communiquent par D-Bus via des interfaces documentées.
- Aucune couleur, police ni nom n'est codé en dur : tout passe par les tokens de `branding/`.
- Toute décision structurante fait l'objet d'un ADR dans `docs/adr/`.
