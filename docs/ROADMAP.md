# Roadmap

État au 19 novembre 2026 — shell 0.26.13. Phase en cours : **consolidation vers la 1.0** (ADR 0039).

| Phase | Contenu | État |
|---|---|---|
| 0 — Fondations | Monorepo, ADR, CI, branding, licence (GPL-3) | ✅ |
| 1 — ISO | live-build trixie, Calamares (chiffrement, Secure Boot, btrfs), Plymouth, GRUB, SDDM VinX | ✅ |
| 2 — Design | Identité claire et verte, tokens, icônes, IBM Plex Sans, accents (ADR 0018, 0021) | ✅ |
| 3 — Shell | Barre, dock, centre de contrôle, notifications, recherche, widgets, menu global, verrouillage, extinction, agent polkit (« sans KDE », ADR 0028) | ✅ |
| 4 — Paramètres | Pages natives (écrans, Wi-Fi, son, énergie, imprimantes, pilotes, utilisateurs, sauvegarde, dépannage, mises à jour, accessibilité, clavier) | ✅ à valider sur matériel |
| 5 — Applications | Store, Fichiers (KIO), Terminal, Mises à jour, Moniteur, Capture, Presse-papiers, Images | ✅ à valider sur matériel |
| 5 bis — Système | Instantanés btrfs + retour arrière au démarrage (ADR 0031), sauvegarde des documents | ✅ à valider sur ISO neuve |
| 5 ter — Traduction | Anglais (ADR 0034) | ✅ sauf catalogue du Store, noms d'accents, messages des scripts |
| **6 — Consolidation** | Gel des fonctions, recette sur matériel ([RECETTE.md](RECETTE.md)), corrections, qualité | ⏳ **en cours** |
| 7 — Publication 1.0 | ISO signée, site (vinxlabs.fr/VinX-OS), guide utilisateur, notes de version | à venir |

## Phase 6 — Consolidation (détail)

| # | Étape | Qui | État |
|---|---|---|---|
| 6.1 | Gel des fonctions 1.0, liste « après 1.0 » (ADR 0039) | Claude | ✅ |
| 6.2 | Nettoyage du dépôt, branche `main` | Claude | ✅ |
| 6.3 | Activer le dépôt APT ([APT.md](APT.md)) | utilisateur | ✅ |
| 6.4 | ISO neuve, installation btrfs, déroulé de [RECETTE.md](RECETTE.md) | utilisateur | ⏳ |
| 6.5 | Corrections issues de la recette (1er rapport : 0.26.4 ; version unique et fonds, ADR 0040) | Claude | ⏳ |
| 6.6 | Traduction restante (Store, accents, notifications des scripts, installateur, écran de connexion) | Claude | ✅ |
| 6.7 | Passe de qualité : relecture de code, tests manquants, cohérence visuelle, accessibilité clavier/contrastes, absence de commandes système (contrastes testés, menus au clavier, outils installés testés, boucles de liaison, fumée de toutes les pages, outils administrateur relus et testés, shellcheck des scripts du shell) | Claude | ✅ |
| 6.8 | Vérification des licences des éléments fournis (polices, logos tiers, fonds) — [LICENCES.md](LICENCES.md) | Claude | ✅ |

## Phase 7 — Publication 1.0

1. Version `1.0.0` (shell et ISO), étiquette `shell-v1.0.0`, entrée de changelog « 1.0 ».
2. ISO `vinx-1.0-amd64.iso` + `SHA256SUMS` + `SHA256SUMS.asc` (signée avec la clé du projet), publiée en
   *release* GitHub.
3. Site `vinxlabs.fr/VinX-OS/` (sources : `web/`), guide nouveaux utilisateurs, notes de version,
   configuration requise et matériel testé.
4. Modèles de tickets GitHub (bogue, matériel), `CONTRIBUTING.md`, `SECURITY.md`.

## Après 1.0

Comptes en ligne, réseau expert (802.1X, proxy), lecteur PDF VinX, autres langues, ISO arm64.
