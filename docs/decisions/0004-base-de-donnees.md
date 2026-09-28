# 0004. PostgreSQL comme base de données

- Statut : acceptée
- Date : 2026-09-28

## Contexte

L'app a été générée avec SQLite, le défaut de Rails 8. PostgreSQL avait été envisagé au départ : le développeur le maîtrise, et `jsonb` est pratique pour les attributs variables des éléments (`Item#properties`) et les futures fiches plantes générées par l'IA.

## Décision

PostgreSQL 18, dès le départ.

- **Développement et test** : serveur local (Postgres.app ou Homebrew), bases `easy_home_development` et `easy_home_test`.
- **Production** : accessory Kamal `db` (`postgres:18`) sur le même serveur que l'app, exposé uniquement en local. Quatre bases : `easy_home_production`, plus `_cache`, `_queue` et `_cable` pour Solid Cache, Solid Queue et Solid Cable.
- **CI** : service `postgres:18` dans la GitHub Action.

## Alternatives écartées

**SQLite** : aucun service à déployer, pleinement supporté par Rails 8 en production. Écarté parce que :

- le déploiement de PostgreSQL avec Kamal reste simple ;
- `jsonb` et le typage strict sont utiles ;
- partir sur la base cible évite une migration ultérieure et les bugs que le typage laxiste de SQLite masque.

## Conséquences

- Utiliser `jsonb` pour les colonnes JSON.
- Mettre en place des sauvegardes de l'accessory (ex. `pg_dump` planifié vers un stockage externe) avant d'y stocker des données réelles.
- Secrets Kamal : `POSTGRES_PASSWORD` (accessory) et `EASY_HOME_DATABASE_PASSWORD` (app), définis dans `.kamal/secrets`.
