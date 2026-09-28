# Roadmap

Chaque étape produit quelque chose d'utilisable. Cocher au fur et à mesure.

## Étape 0 : finir le setup

- [ ] Premier commit de l'app générée
- [x] Passage à PostgreSQL (ADR 0004) : Gemfile, `database.yml`, Dockerfile, accessory Kamal, CI
- [ ] Sauvegardes de la base de production (`pg_dump` planifié)
- [x] Remplacer Minitest par RSpec :
  - [x] `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`, `pundit-matchers`
  - [x] Supprimer `test/` et le railtie `rails/test_unit` dans `config/application.rb`
  - [x] Mettre à jour `config/ci.rb` (`bundle exec rspec`) et `.github/workflows/ci.yml`
  - [x] Configurer les générateurs (`config.generators`) pour RSpec, factories, sans helpers ni specs de vues
- [x] System specs : `capybara` + `cuprite`
- [x] Gems d'architecture : `dry-monads`, `view_component`, `pundit`, `ice_cube`
- [ ] Vitest + happy-dom (`yarn test`), ajouté à `bin/ci`
- [ ] Authentification : `bin/rails generate authentication` (active `bcrypt`)
- [ ] `config.time_zone = "Indian/Reunion"`, `config.i18n.default_locale = :fr`, `rails-i18n`
- [ ] Layout de base Tailwind, pensé mobile d'abord

## Étape 1 : app Rails utilisable sur le web mobile

- [ ] Foyer et membres (`Household`, `Membership`)
- [ ] Moteur de récurrence (`app/domain/recurrence`), testé de façon exhaustive
- [ ] Tâches manuelles et échéances (`Task`, `TaskOccurrence`)
- [ ] Validation, saut d'échéance, journal
- [ ] Catalogue YAML et éléments (`Item`) : poubelles, lave-vaisselle, piscine, un animal
- [ ] Tableau de bord : en retard, aujourd'hui, à venir
- [ ] Job qui marque les échéances manquées

## Étape 2 : coque Hotwire Native Android

- [ ] Projet `android/`, webview pointant vers l'app
- [ ] Path configuration servie par Rails
- [ ] Déploiement Kamal avec HTTPS public

## Étape 3 : notifications push simples

- [ ] Firebase, enregistrement des appareils (`Device`)
- [ ] Job récurrent d'envoi des rappels + relances
- [ ] Bouton « notification de test »

## Étape 4 : action « Fait » native

- [ ] Jeton d'API par appareil, API `api/v1`
- [ ] Action de notification qui valide sans ouvrir l'app

## Étape 5 : invités

- [ ] Rôle `guest`, `TaskAccess` avec période, policies et scopes
- [ ] Invitation par lien

## Après le MVP

Voir la section « Hors MVP » de `docs/produit.md` : tournantes, module plantes avec IA, stocks, mesures, météo et mode cyclone…
