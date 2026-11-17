# ADR 0021 — Couleur d'accent au choix et fond « VinX Logo » dynamique

- **Statut** : accepté (modifie la règle « un seul accent » de l'ADR 0018)
- **Date** : 2026-11-17

## Contexte

L'ADR 0018 fixait le vert du logo comme unique accent. L'utilisateur souhaite pouvoir choisir sa
couleur, et voir le logo du fond d'écran prendre cette couleur. Maquettes validées le 17/11/2026
(8 couleurs, Graphite gardé, option « Automatique »).

## Décision

- **Nuancier fermé de 8 accents** dans `branding/tokens.toml` (`[accents.*]`) : Vert VinX
  (défaut), Lagon, Turquoise, Citron, Ambre, Corail, Framboise, Graphite. Pas de couleur libre :
  chaque accent a trois valeurs vérifiées — `fill` (remplissage), `ink` (encre posée dessus,
  ≥ 4,5:1), `text` (texte coloré sur fond clair, ≥ 4,5:1 ; sur fond sombre on utilise `fill`).
  Violet et indigo restent exclus.
- **Préférence** `appearance/accent` = identifiant (`vert`, `lagon`…) ou `auto`. Une valeur
  inconnue (dont les anciennes valeurs hexadécimales) revient au vert.
- **Theme** : `Theme.accentId` (réglé par `AppearanceSync`), `Theme.accents` (nuancier),
  `Theme.accentEntry` ; `accent`, `accentForeground`, `accentText` et `logo` en dérivent.
  `accentOverride` est supprimé.
- **Automatique** : `Session.pickAccent()` (analyse testée dans `accentpick.h`) prend la teinte
  dominante du fond d'écran personnel, pondérée par la saturation, et choisit l'accent de teinte la
  plus proche ; une image terne donne Graphite. Avec le fond « VinX Logo », l'automatique garde
  le vert (le fond prend déjà la couleur d'accent).
- **Fond « VinX Logo » dessiné en direct** (`Vinx.Controls/LogoWallpaper`) : même composition que
  le SVG (espace 3840 × 2160 recadré), grille de points en Canvas, logo en `Icon` teinté, fondu
  enchaîné au changement d'accent. « VinX Logo » suit le thème clair/sombre ;
  « VinX Logo Sombre » reste sombre. Utilisé par le bureau, l'écran de verrouillage et la vignette
  de Paramètres → Fond d'écran. Les PNG installés restent pour les autres environnements.

## Conséquences

- L'écran de connexion (SDDM) reste vert : il tourne avant la session, sans accès aux
  préférences de l'utilisateur. Le synchroniser demanderait un export système (via `vinx-admin`),
  à décider plus tard.
- Les applications tierces (GTK, Qt hors VinX) ne suivent pas encore l'accent.
