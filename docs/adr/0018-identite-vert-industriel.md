# ADR 0018 — Identité « industrielle » : vert du logo, thème clair, IBM Plex Sans

- **Statut** : accepté (remplace les choix de couleurs, d'icônes et de fond des ADR 0015)
- **Date** : 2026-11-16

## Contexte

Les versions précédentes (gris foncé + violet, biseau partout) étaient jugées génériques,
« faites avec une IA ». L'identité part désormais des goûts de l'utilisateur : design industriel
(Braun, Teenage Engineering, Nothing) et tech sobre ; nouveau logo vert fourni par l'utilisateur.

## Décision

| Élément | Choix |
|---|---|
| Couleur | Vert du logo `#10DD8C`, seul accent, jamais en dégradé. Encre `#06130D` posée dessus (10,6:1) ; nuance foncée `#0A7F51` pour le texte vert sur fond clair (4,7:1). |
| Thème par défaut | **Clair** : blanc cassé chaud `#ECEBE6` / surfaces `#F8F7F4`, encre `#141414`. Sombre disponible. |
| Police | **IBM Plex Sans** (fournie avec vinx-shell dans `/usr/share/fonts/opentype/ibm-plex-sans`, licence SIL OFL). Pas d'étiquettes en police technique. |
| Fond d'écran | « VinX Logo » : grille de points + logo vert en grand, décalé à droite (variante sombre). |
| Icônes VinX | Tuile neutre arrondie, pictogramme à l'encre au trait, un point de couleur par application. |
| Applications tierces | Logo officiel (Firefox, LibreOffice, Thunderbird…), posé sur la même tuile neutre. |
| Formes | Douces ; le trait d'accent animé reste la signature. |
| Démarrage, connexion, verrouillage | Fond clair à points, logo vert, carte claire. |

## Conséquences

- Les interrupteurs et curseurs verts sur fond clair ont un contraste faible (1,7:1) : l'état
  reste lisible par la position du bouton et le texte (règle « jamais la couleur seule »).
- Thèmes KDE (VinXLight par défaut, VinXDark), GTK (Breeze clair), Calamares, Plymouth et SDDM
  alignés sur cette palette.
