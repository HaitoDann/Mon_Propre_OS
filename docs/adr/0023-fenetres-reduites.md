# ADR 0023 — Retrouver les fenêtres réduites

- **Statut** : accepté
- **Date** : 2026-11-17

## Contexte

Retour du portable : deux fenêtres réduites devenues introuvables. Le dock ne distinguait pas
une fenêtre réduite d'une fenêtre visible, et un clic sur une application à plusieurs fenêtres
envoyait « activer » au groupe, sans effet dans libtaskmanager. Maquettes : options A (liste au
clic) + C (vue d'ensemble) retenues ; B (zone « réduites » dans le dock) écartée car redondante.

## Décision

- **Indicateurs** : un point par fenêtre (trois au plus), plein si visible, creux si réduite.
- **Clic** : une fenêtre → la ramène (`requestActivate`, qui la sort de la réduction) ou la réduit
  si elle est au premier plan ; plusieurs fenêtres → menu « liste des fenêtres » (titre, mention
  « Réduite », fenêtre active cochée, accès à « Toutes les fenêtres »).
- **API des fournisseurs de tâches** (KDE et aperçu) : `windows(i)`, `activateWindow(i, j)`,
  `minimizeWindow(i, j)`, `revision` (rafraîchit les liaisons).
- **Vue d'ensemble** : bouton en grille dans la barre et Méta+W (raccourci KWin « Overview »).
  La touche Méta seule reste la recherche (maquette : Super ; changé pour ne pas casser l'habitude).
- Liste en texte, sans miniatures : les miniatures (capture PipeWire de KWin) seront envisagées
  plus tard, elles ne sont pas vérifiables hors matériel réel.

## Conséquences

- Le code KDE (`KdeTasksBackend.qml`) n'est exercé qu'en session réelle : à valider sur le portable.
