# ADR 0027 — Store : vitrine avec rayons, Debian et Flathub mélangés

- **Statut** : accepté
- **Date** : 2026-11-18

## Contexte

Le Store présentait des « packs » Flathub et une recherche séparée Flathub / Debian, sans logos pour
les logiciels non installés. Maquette validée : rayons à gauche, sources mélangées avec badge,
« Sélection VinX ».

## Décision

- **Rayons à gauche** : À la une, Rechercher, Installées, Mises à jour (ouvre l'application
  « Mises à jour »), puis huit catégories (Bureautique, Internet, Graphisme et photo, Audio et vidéo,
  Jeux, Éducation, Développement, Outils système).
- **Catalogue choisi** (`apps/store/Catalog.js`) : pour chaque logiciel, paquet Debian (prioritaire)
  et/ou identifiant Flathub, nom et résumé en français. Logiciel introuvable dans les deux sources :
  masqué. « Sélection VinX » : un logiciel mis en avant, tiré au sort à chaque ouverture.
- **Logos** : icônes AppStream de Debian en cache (`/var/cache/swcatalog/icons/…`, chemins
  `cached:` d'`appstreamcli`, résolution testée `resolveAppstreamIcon`) ; icônes du cache AppStream
  de Flatpak pour Flathub ; à défaut, initiales sur une tuile à la couleur du rayon.
- **Recherche unique** : Debian puis Flathub dans la même liste, badge de source ; une application
  Flathub du même nom qu'un résultat Debian est masquée.
- `DebianPackages.lookup()` charge les fiches du catalogue une à une (`appstreamcli search`),
  état « installé » par `dpkg-query`.

## Conséquences

- Les logos Debian n'apparaissent que si le cache d'icônes AppStream existe (paquet `appstream`,
  `apt update`) ; sinon, initiales.
- Le catalogue est maintenu à la main : à enrichir au fil des retours.
