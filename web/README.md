# Site web de VinX OS

Page produit `vinxlabs.fr/vinx-os/`, sur le modèle de la page Nilo du dépôt `vinx-labs`
(même squelette, `/assets/shell.css` commun, thème vert VinX, IBM Plex Sans).

## Mise en ligne (dans le dépôt vinx-labs)

```bash
cp -r ~/Mon_Propre_OS/web/vinx-os ~/vinx-labs/
```

Puis, dans `vinx-labs` : ajouter une carte « VinX OS » sur `index.html` (à côté de Nilo), l'URL dans
`sitemap.xml`, commiter et pousser sur `main`.

## Captures

La section « Aperçu » reste masquée tant que les images n'existent pas. Les produire sur le portable
avec `vinx-dev rapport`, puis copier dans `vinx-os/assets/` :
`capture-bureau.png`, `capture-controle.png`, `capture-parametres.png`, `capture-store.png`
(et `og-vinx-os.png`, 1200×630, pour les partages).

## Téléchargement

Les boutons pointent vers la dernière *release* GitHub de `HaitoDann/VinX_OS` ; le script y prend le
fichier `.iso` et `SHA256SUMS` automatiquement.
