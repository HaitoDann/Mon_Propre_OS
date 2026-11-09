# VinX OS — distribution Linux de bureautique

> Le nom et l'identité visuelle se définissent dans [`branding/`](branding/).

Distribution basée sur **Debian 13 « Trixie »** (amd64), pensée pour la bureautique et la productivité.
Trois piliers : **simplicité, ergonomie, stabilité**.

## Structure du monorepo

| Dossier | Rôle |
|---|---|
| `docs/` | Décisions d'architecture (ADR), roadmap, spécifications |
| `branding/` | Identité visuelle : source de vérité unique (nom, couleurs, logos) |
| `prototype/` | Maquette web interactive de l'interface (référence UX) |
| `design-system/` | Bibliothèque de composants QML |
| `shell/` | Shell de bureau (Qt 6 / QML + KWin) |
| `session/` | Écran de connexion, session, premier démarrage |
| `apps/settings`, `apps/store` | Applications système |
| `packaging/` | Paquets Debian |
| `distro/` | Construction de l'ISO (live-build, Calamares) |
| `ci/` | Pipelines d'intégration continue |

## Voir la maquette

Ouvrez `prototype/index.html` dans un navigateur : aucune installation n'est nécessaire.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)
- [Décisions (ADR)](docs/adr/)
