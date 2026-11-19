# Licences des éléments fournis par VinX OS

Inventaire de l'étape 6.8 (feuille de route), vérifié le 19 novembre 2026.

| Élément | Emplacement | Licence | Remarque |
|---|---|---|---|
| Code (shell, applications, scripts, ISO) | `shell/`, `distro/`, `tools/` | GPL-3.0-or-later (ADR 0012) | `LICENSE` à la racine |
| IBM Plex Sans | `branding/fonts/ibm-plex-sans` | SIL OFL 1.1 | `OFL.txt` fourni, déclaré dans `debian/copyright` |
| IBM Plex Mono (Terminal) | `branding/fonts/ibm-plex-mono` | SIL OFL 1.1 | `OFL.txt` fourni, déclaré dans `debian/copyright` (ajouté le 19/11) |
| Pictogrammes d'interface | `branding/icons` | CC BY-SA 4.0 | Dessinés pour VinX (ne reprennent pas les tracés de Lucide ou Feather) |
| Thème d'icônes « VinX » | généré depuis `branding/icons` | CC BY-SA 4.0 | Hérite de Breeze (LGPL) pour les icônes absentes : Breeze n'est pas copié |
| Fonds d'écran, Plymouth, GRUB | `branding/wallpaper`, `branding/boot` | CC BY-SA 4.0 | Fonds violets retirés (ADR 0040) |
| Logo VinX et nom « VinX OS » | `branding/logo` | Marque, tous droits réservés | Un dérivé redistribué doit changer de nom et de logo |
| Logos des applications tierces | — | Ceux de leurs projets | **Aucun n'est copié dans le dépôt** : ils viennent des paquets Debian, de Flathub (AppStream) ou du thème hérité |
| Catalogue du Store | `shell/apps/store/Catalog.js` | GPL (texte écrit pour VinX) | Noms de logiciels cités à titre descriptif |

## Points d'attention

- Le site (`web/VinX-OS`) charge IBM Plex Sans depuis **Google Fonts** : la licence le permet, mais
  cela transmet l'adresse IP des visiteurs à Google (sujet RGPD). Héberger la police avec le site
  (fichiers de `branding/fonts`) évite cette transmission.
- Les noms et logos Debian, Firefox, LibreOffice, Thunderbird ne sont utilisés que pour désigner
  ces logiciels ; aucune variante modifiée de leurs logos n'est fournie.
