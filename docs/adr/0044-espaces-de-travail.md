# ADR 0044 — Espaces de travail VinX

- **Statut** : proposé (maquette validée dans ses principes le 20/11/2026, en attente du feu vert pour coder)
- **Date** : 2026-11-20

## Contexte

L'utilisateur veut garder l'interface actuelle (barre en haut, dock universel en bas) et y ajouter des
espaces de travail repérables. Plusieurs constats de recherche ont guidé la conception :
- les gens regroupent leur travail par activité (Rooms, Giornata, Bardram) ;
- un dock qui change selon la tâche déroute (GroupBar) ;
- les bords d'écran sont les cibles les plus rapides à la souris (loi de Fitts) ;
- reconnaître une couleur est plus facile que lire un nom (heuristique de reconnaissance de Nielsen).

Maquette : « Espaces VinX » (20/11/2026).

## Décision

- **Espace** = bureau virtuel KWin, auquel s'ajoutent un nom, une couleur facultative (aucune par défaut) et un
  dossier facultatif. Ces réglages sont stockés dans `shell.ini`, section `spaces/`.
- **Bouton** : les points des bureaux, déjà présents dans la barre, ouvrent le menu des espaces. Ce menu affiche
  pour chaque espace une miniature, son nom, son dossier et son raccourci Méta+1…9, ainsi que « Nouvel espace » et « Modifier ».
- **Couleur** : « accent + fond ». Dans un espace coloré, l'accent du système prend la couleur de l'espace,
  et le fond d'écran reçoit un halo de cette couleur (le logo du fond « VinX Logo » suit l'accent).
- **Dock du bas** : universel. Il montre les applications ouvertes de **tous** les espaces. Un clic sur une
  fenêtre ouverte dans un autre espace mène à cet espace.
- **Tiroir latéral** : il s'ouvre quand le curseur reste environ 250 ms contre le bord gauche, et se ferme dès que
  le curseur s'en éloigne. Étroit, sobre, sans étiquettes (le nom s'affiche au survol), il contient :
  le dossier de l'espace, les raccourcis épinglés (par glisser-déposer) et les documents récents de l'espace.
- Le dock à gauche reste une option distincte. Si le dock est placé à gauche, le tiroir se désactive.

## Étapes

1. Espaces : noms, menu dans la barre, Méta+1…9, bandeau du nom au changement.
2. Couleur par espace (accent + halo du fond), à partir du réglage d'accent existant (ADR 0021).
3. Tiroir latéral : fenêtre layer-shell au bord gauche, raccourcis et dossier.
4. Documents récents par espace (journal de l'espace, à partir des fichiers ouverts quand il est actif).

## Points ouverts

- Comportement du bord gauche avec une fenêtre agrandie (barres de défilement collées au bord) : à vérifier
  sur le portable.
- Le changement d'accent régénère la décoration des fenêtres (vinx-window-theme), ce qui pourrait être trop lent
  pour un changement d'espace fréquent. Si c'est le cas, l'accent de la décoration restera fixe.
