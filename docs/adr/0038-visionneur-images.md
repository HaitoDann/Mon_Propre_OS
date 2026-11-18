# ADR 0038 — Visionneur d'images VinX

- **Statut** : accepté
- **Date** : 2026-11-18

## Contexte

Gwenview (KDE) est l'application ouverte par défaut pour les images ; son interface est très chargée
pour regarder des photos, et ses retouches sont dispersées. Maquette retenue : proposition A
« immersive », mode Modifier tel que proposé. Les PDF auront une application à part, plus tard.

## Décision

`vinx-images` (`shell/apps/viewer`), application par défaut des images (`mimeapps.list`), Gwenview masqué.

- **Affichage immersif** : fond sombre quel que soit le thème, titre et position (« 3 / 24 ») en haut,
  barre flottante (zoom, Pivoter, Modifier, Infos, Diaporama, Partager), miniatures en bas ; barres masquées
  après 2,5 s d'immobilité. Ajustée à la fenêtre sans agrandir les petites images, molette = zoom autour du
  pointeur, double-clic = Ajuster ↔ 100 %. GIF et WebP animés.
- **Clavier** : ← →, Début/Fin, + − 0 1, R (pivoter), I (infos), E (modifier), F/F11, Suppr (corbeille),
  Ctrl+C, Échap.
- **Pivoter** dans le visionneur n'écrit rien tant qu'on n'a pas cliqué « Enregistrer » (bandeau).
- **Infos** à la demande : fichier, taille, dimensions, format, date de prise de vue, appareil, réglages
  (lecture EXIF minimale, `exif.h`, testée), dossier, « Ouvrir avec… », « Fond d'écran ».
- **Partager** : copier (confié au shell, ADR 0037), envoyer par e-mail (`xdg-email`), fond d'écran,
  dossier, ouvrir avec, corbeille.
- **Modifier** : recadrer (libre, original, carré, 16:9, 4:3), pivoter, miroir, luminosité, contraste,
  annotations de la capture d'écran (même code `captureutil.h`), « Réduire pour un mail (1600 px) ».
  Aperçu sur une image réduite (2400 px), rendu final en pleine résolution. **Enregistrer une copie**
  par défaut (« Photo (modifiée).jpg ») ; « Remplacer l'original » demande une confirmation. Écriture
  atomique (`QSaveFile`).
- Formats : ceux des greffons d'images de Qt ; WebP par `qt6-image-formats-plugins`, HEIC et AVIF par
  `kimageformat6-plugins` (recommandés).

## Conséquences

- Les retouches enregistrées perdent les données EXIF (l'orientation est appliquée aux pixels).
- Pas de bibliothèque photo (albums, visages) : on parcourt les dossiers, comme Fichiers.
- Non vérifié ici : HEIC et AVIF (greffons absents), `xdg-email` avec Thunderbird, l'association par
  défaut dans une vraie session.
