# ADR 0002-qt6-qml-kwin — Shell en Qt 6 / QML sur KWin

- **Statut** : accepté
- **Date** : 2026-11-09

## Contexte
Il faut un bureau sur mesure, fluide et animé, sans écrire de compositeur.

## Décision
Shell et apps système en Qt 6 / QML (logique C++). KWin sert de compositeur Wayland. GTK et un compositeur Rust maison ont été écartés.

## Conséquences
Rendu et animations maîtrisés ; on profite de la maturité de KWin (multi-écran, HiDPI, accessibilité). Dépendance à l'écosystème KDE pour le compositeur.
