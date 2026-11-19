# Roadmap

Chaque étape produit quelque chose d'utilisable. Cocher au fur et à mesure.

Ordre : valider le produit avant de l'industrialiser. Maquettes, puis une première version centrée sur les plantes,
puis le risque technique (Hotwire Native et push), et le déploiement seulement quand l'app Android en a besoin. Le flux
de livraison complet (Docker, agent relecteur, staging) est gelé sur la branche `chore/flux-de-livraison`.

## Étape 0 : setup

- [x] Premier commit de l'app générée
- [x] Passage à PostgreSQL (ADR 0004) : Gemfile, `database.yml`, Dockerfile, accessory Kamal, CI
- [x] RSpec, FactoryBot, shoulda-matchers, pundit-matchers ; Capybara + Cuprite ; Vitest + happy-dom
- [x] Gems d'architecture : `dry-monads`, `view_component`, `pundit`, `ice_cube`
- [x] Authentification Rails 8
- [x] Fuseau `Indian/Reunion`, locale `fr`, `rails-i18n`
- [x] Socle de tests et CI GitHub (garde-fous des specs, audits, budget de temps)

## Étape 1 : maquettes

- [ ] Maquettes HTML cliquables, mobile d'abord et élargies sur desktop : liste des plantes, fiche d'une plante
  (arrosage, photos, analyses), ajout d'une plante, résultat d'une analyse, ma maison (adresse, emplacements)
- [ ] Validation sur téléphone, corrections

## Étape 2 : première version, les plantes

- [x] Layout de base Tailwind, pensé mobile d'abord
- [x] Foyer minimal (`Household`, `Membership` owner), comptes créés en console (`bin/rails accounts:create`)
- [ ] Moteur de récurrence : `Recurrence::Sliding`, testé de façon exhaustive
- [ ] Ma maison : adresse avec autocomplétion, position et altitude (ADR 0009), emplacements (`Location`) avec
  exposition et abri
- [ ] Plantes : `Item` (`kind: plant`), emplacement, espèce
- [ ] Photos (Active Storage) et suivi photo
- [ ] `Plants::Analyzer` via `claude -p` (ADR 0008), job d'analyse, faux adaptateur en test
- [ ] Identification de l'espèce proposée, confirmée ou corrigée
- [ ] Arrosage : tâche `plant.watering`, bouton « Arrosée », journal
- [ ] Analyse d'une photo : état, observations, actions ; action acceptée → tâche
- [ ] System specs des parcours : ajouter une plante, arroser, analyser une photo

## Étape 3 : coque Hotwire Native Android et push (spike)

- [ ] Projet `android/`, webview pointant vers l'app
- [ ] Une notification FCM « à arroser » qui arrive au bon moment

## Étape 4 : déploiement minimal

- [ ] Kamal vers le serveur de la maison, HTTPS public via le tunnel
- [ ] CLI `claude` et jeton dans l'image (ADR 0008)
- [ ] Sauvegardes de la base de production (`pg_dump` planifié)

## Étape 5 : le reste du MVP

- [ ] Tâches manuelles, récurrences fixes et basées sur l'usage
- [ ] Catalogue : poubelles, lave-vaisselle, piscine, un animal
- [ ] Tableau de bord : en retard, aujourd'hui, à venir ; job des échéances manquées
- [ ] Notifications avec relance, action « Fait » native (`Device`, API `api/v1`)
- [ ] Membres et invités (`TaskAccess`, invitation par lien)

## Après le MVP

Voir la section « Hors MVP » de `docs/produit.md`.