# Easy Home

Rappels des tâches de la maison, notifications au bon moment et journal de ce qui a été fait.

Rails 8.1 + Hotwire, avec une app Android Hotwire Native (à venir).

## Prérequis

- Ruby 4.0.7 (`.ruby-version`)
- Node 25.1.0 (`.node-version`) et Yarn
- PostgreSQL 18 en local (Postgres.app ou Homebrew)

## Démarrer

```bash
bin/setup     # dépendances, base de données
bin/dev       # http://localhost:3000
```

## Vérifier

```bash
bin/ci        # lint, audits de sécurité, tests
```

## Déployer

```bash
bin/kamal deploy
```

## Documentation

- `CLAUDE.md` : vue d'ensemble, conventions, règles d'architecture (point d'entrée, aussi pour les assistants IA)
- `docs/` : produit, domaine, architecture, tests, Hotwire Native, roadmap, décisions (ADR)
