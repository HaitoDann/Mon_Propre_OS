# ADR 0040 — Version unique de VinX OS, retrait des fonds violets et « Biseau »

- **Statut** : accepté
- **Date** : 2026-11-19

## Contexte

La recette sur le portable (rapport du 19/11/2026, shell 0.26.3) a relevé deux incohérences :

1. **Deux numéros de version.** À propos et Mises à jour affichaient « VinX OS 0.17 », version de
   l'ISO écrite une fois pour toutes dans `/etc/vinx-release`, à côté de « Bureau VinX 0.26.3 ».
   Les mises à jour par le dépôt APT ne changeaient jamais le premier numéro. De plus, une mise à jour
   de `base-files` (Debian) réécrit `/usr/lib/os-release` et rend au système le nom « Debian ».
2. **Fonds d'écran hors charte.** « VinX Nebula », « VinX Nebula épuré » (violets) et « VinX Biseau »
   étaient encore proposés, alors que l'identité en vigueur (ADR 0018, `docs/DESIGN.md`) exclut le
   violet et ne garde le biseau que comme option cachée.

## Décision

- **Version unique** : la version de VinX OS **est** celle du paquet `vinx-shell`.
  - `/usr/lib/vinx/vinx-release` (installé par le paquet) écrit `/etc/vinx-release`, `NAME`,
    `PRETTY_NAME` et `VINX_VERSION` dans `/usr/lib/os-release`, et `/etc/issue`.
  - Le `postinst` l'appelle à chaque installation ou mise à jour ; un déclencheur dpkg
    (`interest-noawait /usr/lib/os-release`) le rappelle quand `base-files` réécrit ce fichier.
  - L'ISO prend le même numéro (`distro/build.sh` lit `shell/debian/changelog`) ; `brand.toml`
    ne porte plus de version.
- **Fonds retirés** : les trois fonds sont supprimés de l'ISO et des sources (toujours dans
  l'historique git). Sur les systèmes déjà installés, ils ne sont plus proposés dans Paramètres et,
  s'ils étaient choisis, le bureau revient à « VinX Logo ». Restent : VinX Logo, VinX Logo (sombre),
  VinX Graphite et les fonds de KDE.

## Conséquences

- Une mise à jour APT affiche immédiatement la nouvelle version partout (À propos, Mises à jour,
  écran de connexion, consoles).
- `/usr/lib/os-release` reste modifié hors de son paquet (`dpkg --verify` le signale), comme avant
  avec le hook de l'ISO ; un détournement (`dpkg-divert`) n'apporterait rien de plus ici.
- Les fichiers des fonds retirés restent sur les systèmes installés avant ce changement (ils
  n'appartiennent à aucun paquet) ; ils sont simplement ignorés.
