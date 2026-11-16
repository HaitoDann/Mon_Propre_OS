# ADR 0017 — Démarrage, connexion et animation signature

- **Statut** : accepté
- **Date** : 2026-11-16

## Décision

- **Démarrage (Plymouth)** : thème script `vinx` propre (plus dérivé de « spinner ») : fond
  « Biseau », logo en fondu, barre de progression biseautée violette, champ biseauté pour le
  mot de passe du disque chiffré (LUKS), messages en bas.
- **Connexion (SDDM)** : thème `vinx` en QML (API SDDM 2, Qt 6) qui réutilise les modules
  `Vinx.Theme` et `Vinx.Controls` : heure, carte de connexion biseautée, choix du compte,
  session, veille / redémarrage / extinction, secousse en cas d'erreur, alerte majuscules.
  Le verrouillage d'écran (kscreenlocker) reprend les mêmes formes.
- **Animation signature** : les panneaux, notifications et cartes arrivent **le long de la
  diagonale du biseau** (du coin coupé vers leur place), puis un **trait d'accent dessine
  l'angle coupé** (`Bevel.edgeProgress`). Respecte « Réduire les animations » (durées à 0).

## Conséquences

- Le thème SDDM dépend des modules QML VinX installés par `vinx-shell` ; Breeze reste installé
  comme thème de secours de SDDM.
- Le thème Plymouth doit être reconstruit dans l'initramfs (hook 0910).
