# Site web de VinX OS

Page produit **`vinxlabs.fr/VinX-OS/`**, publiée dans le dépôt `vinx-labs` (dossier `VinX-OS/`), sur le
modèle de la page Nilo (même squelette, `/assets/shell.css` commun, thème vert VinX, IBM Plex Sans).
Sources de référence : `web/VinX-OS/` ici ; toute modification se reporte dans `vinx-labs/VinX-OS/`.

Pour l'instant la page n'est **pas annoncée** : absente de l'accueil et du `sitemap.xml`, `noindex`.
Pour l'annoncer (1.0) : retirer la balise `robots`, ajouter une carte sur `index.html` et l'URL au sitemap.

## Captures

La section « Aperçu » reste masquée tant que les images n'existent pas. Les produire avec
`vinx-dev rapport`, puis copier dans `VinX-OS/assets/` : `capture-bureau.png`, `capture-controle.png`,
`capture-parametres.png`, `capture-store.png` (et `og-vinx-os.png`, 1200×630, pour les partages).

## Téléchargement

Les boutons pointent vers la dernière *release* GitHub de `HaitoDann/VinX_OS` ; le script y prend le
fichier `.iso` et `SHA256SUMS` automatiquement.
