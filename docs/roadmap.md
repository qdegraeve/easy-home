# Roadmap

Chaque étape produit quelque chose d'utilisable. Cocher au fur et à mesure.

Ordre : valider le produit avant de l'industrialiser. Maquettes, puis une première version centrée sur les plantes,
puis le risque technique (Hotwire Native et push), et le déploiement seulement quand l'app Android en a besoin. Le flux
de livraison complet (Docker, agent relecteur, staging) est gelé sur la branche `chore/flux-de-livraison`.

## Étape 0 : setup

- [x] Premier commit de l'app générée
- [x] Passage à PostgreSQL (ADR 0004) : Gemfile, `database.yml`, Dockerfile, accessory Kamal, CI
- [x] RSpec, FactoryBot, shoulda-matchers, pundit-matchers ; Capybara + Cuprite ; Vitest + happy-dom
- [x] Gems d'architecture : `dry-monads`, `view_component`, `pundit` (`ice_cube`, jamais utilisée, retirée en PR 2, ADR 0016)
- [x] Authentification Rails 8
- [x] Fuseau `Indian/Reunion`, locale `fr`, `rails-i18n`
- [x] Socle de tests et CI GitHub (garde-fous des specs, audits, budget de temps)

## Étape 1 : maquettes

- [ ] Maquettes HTML cliquables, mobile d'abord et élargies sur desktop : liste des plantes, fiche d'une plante
  (arrosage, photos, analyses), ajout d'une plante, résultat d'une analyse, ma maison (adresse, emplacements)
- [ ] Validation sur téléphone, corrections
- [x] Revue UX et maquettes v2 de la refonte (`docs/ux/revue-ux.md`, `docs/maquettes/v2/`), logo et icône
- [x] Refonte en 17 PR, dans l'ordre du découpage de `docs/ux/revue-ux.md` (mise en pause le 23 novembre 2026 ; restent
  4 questions ouvertes : rouge réservé aux confirmations, interrupteurs, écran des emplacements, report groupé)

## Étape 2 : première version, les plantes

- [x] Layout de base Tailwind, pensé mobile d'abord
- [x] Foyers créés dans l'app, plusieurs par utilisateur, foyer actif en session ; comptes créés en console
  (`bin/rails accounts:create`)
- [x] Moteur de récurrence : `Recurrence::Sliding`, testé de façon exhaustive
- [x] Ma maison : adresse avec autocomplétion, position et altitude (ADR 0009), emplacements (`Location`) avec
  exposition et abri
- [x] Plantes : `Plant` (ADR 0010), emplacement, espèce saisie ; archivage et suppression
- [x] Photos (Active Storage, ADR 0011) et suivi photo
- [x] `PlantAnalyzer` via `claude -p` (ADR 0008), job d'analyse, faux adaptateur en test ; analyse de 1 à 5 photos
  avec remarque de l'utilisateur, automatique sur la première photo
- [x] Identification de l'espèce proposée, acceptée d'un bouton ou corrigée à la main
- [x] Arrosage : tâche `plant.watering`, bouton « J'ai arrosé », journal
- [x] Tâches d'une plante : liste sur la fiche, tâche manuelle (engrais, taille…) une seule fois à une date
  (`Recurrence::Once`) ou tous les N jours après la dernière fois
- [x] Analyse d'une photo : état, observations, actions ; intervalle d'arrosage accepté, action acceptée → tâche
- [x] Discussion autour d'une analyse : questions complémentaires, avec photo jointe possible
- [ ] System specs des parcours : ajouter une plante, arroser, analyser une photo

## Étape 3 : coque Hotwire Native Android et push (spike)

- [x] Projet `android/`, webview pointant vers l'app, path configuration servie par Rails
- [ ] Navigation et transitions plus naturelles dans l'app (titres, en-tête web, retours)
- [x] Résumé du matin côté Rails : réglages, enregistrement des téléphones, envoi récurrent (ADR 0012)
- [x] Notifications côté Android : Firebase, permission, enregistrement du téléphone, réception (bridge `push`)
- [x] Prendre une photo directement avec l'appareil du téléphone : fourni par la coque (sélecteur de fichiers de
  Hotwire Native, appareil photo compris), sans code dédié

## Étape 4 : déploiement minimal

- [x] Kamal vers le serveur de la maison, HTTPS public via son propre tunnel Cloudflare
- [ ] CLI `claude` et jeton dans l'image (ADR 0008)
- [x] Sauvegardes chiffrées de la base et des photos (accessory `backup` : restic vers R2, alerte si absente)
- [x] App Android de production signée, à côté de la version de test (`.debug`)
- [x] Envoi des e-mails en production (mot de passe oublié) : relais SMTP de Brevo (ADR 0018)

## Étape 5 : le reste du MVP

- [x] Conception des autres domaines : `docs/conception/equipements-et-taches.md`, ADR 0016 et 0017
- [x] Tâches de la maison, Comment faire et feuille de la tâche (PR 1)
- [x] Récurrence à jour fixe et suggestion poubelles (PR 2)
- [x] Rappels à une heure et relances (PR 3)
- [x] Unités semaines, mois, ans (PR 4) ; photos polymorphes (PR 5)
- [x] Équipements, photos d'une tâche (PR 6) ; « quand il le faut » (PR 7) ; suggestions par type (PR 8)
- [x] Nettoyage (PR 9) : sujet des photos requis en base, ancien format d'intervalle abandonné
- [ ] Suppression de la colonne `photos.plant_id`, ignorée par le modèle
- [ ] Un animal
- [ ] Tableau de bord : en retard, aujourd'hui, à venir ; job des échéances manquées
- [ ] Notifications avec relance, action « Fait » native (`Device`, API `api/v1`)
- [ ] Membres et invités (`TaskAccess`, invitation par lien)

## Après le MVP

Voir la section « Hors MVP » de `docs/produit.md`.