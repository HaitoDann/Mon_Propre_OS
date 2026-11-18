# ADR 0037 — Historique du presse-papiers

- **Statut** : accepté
- **Date** : 2026-11-18

## Contexte

Sous Plasma, l'historique (Klipper) vit dans plasmashell, remplacé par vinx-shell : sans lui, plus
d'historique, et le contenu copié disparaît quand l'application qui l'a copié se ferme (Wayland).

## Décision

- vinx-shell tient l'historique (`Clipboard`, `cliphistory.h` testé) et l'affiche par **Méta+V**
  (`vinx-shellctl clipboard`) : recherche, 50 derniers textes, liens et images, épinglage (Ctrl+P),
  Suppr pour retirer, « Tout effacer » (garde les épinglés).
- **Entrée remet l'élément dans le presse-papiers** ; on colle ensuite avec Ctrl+V. Le collage direct
  demanderait de simuler le clavier dans une autre fenêtre (protocole réservé de KWin) : écarté pour l'instant.
- Le shell n'a jamais le focus : il suit le presse-papiers par `KSystemClipboard` (KGuiAddons, protocole
  Wayland *data-control*). Quand l'application source se ferme, il remet le dernier élément (comme Klipper).
- **Confidentialité** (choix de l'utilisateur) : historique en mémoire seulement, donc effacé à la fermeture de
  session ; seuls les épinglés sont écrits (`~/.local/share/vinx/clipboard`, fichier lisible par l'utilisateur
  seul). Les mots de passe signalés par les gestionnaires (`x-kde-passwordManagerHint: secret`, KeePassXC) ne
  sont jamais gardés ni restaurés. Rien ne quitte l'ordinateur.

## Conséquences

- Nouvelle dépendance de construction : `libkf6guiaddons-dev` (sans elle : presse-papiers de Qt, qui ne voit
  les copies que lorsque le shell a le focus).
- Non vérifié ici : KSystemClipboard sous KWin, la restauration après fermeture d'une application, Méta+V.
