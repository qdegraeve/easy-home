# Stratégie de test

Le code est écrit et relu par des agents, et le chef de projet ne le lit pas : **les tests sont la preuve que l'application fonctionne.** Ils doivent donc être fiables, rapides et complets. Un test qui existe « pour faire joli » est pire que pas de test : il donne une fausse confiance.

## Exigences

### Complets

- **Tous les parcours critiques sont testés de bout en bout** (system specs) : du geste de l'utilisateur jusqu'au résultat visible à l'écran, et à l'effet en base quand il compte (journal, échéance suivante, notification programmée).
- **Chaque critère d'acceptation d'un ticket est couvert** par au moins une spec, citée dans la PR.
- Les cas d'erreur visibles par l'utilisateur sont testés au moins une fois par parcours (saisie invalide, accès refusé).

### Fiables

- Une spec attend un **état**, jamais une durée : matchers Capybara (`have_content`, `have_css`, `have_button`), et leurs formes négatives `have_no_*` (jamais `not_to have_*`, qui attend inutilement ou passe à tort). `sleep` est interdit (`bin/check-specs`).
- Le temps est figé avec `travel_to`. Jamais `Time.now` / `Date.today`.
- Aucune dépendance au réseau, à l'ordre d'exécution (ordre aléatoire) ou à des données laissées par une autre spec.
- On cible ce que voit l'utilisateur (texte, libellé, rôle) plutôt qu'une classe CSS ou une structure HTML.
- Les erreurs JavaScript font échouer la spec (`js_errors: true`).
- **Une spec instable se corrige, elle ne se relance pas** : pas de `rspec-retry`. En CI, chaque system spec ajoutée ou modifiée dans une PR est exécutée trois fois en ordre aléatoire.

### Rapides

- Budget par exemple, appliqué en CI (`spec/support/time_budget.rb`) : **1 s** pour une spec non système, **8 s** pour une spec système (plus une marge pour le premier exemple de chaque sorte). Une spec qui dépasse échoue : on la rend plus rapide, on ne relève pas le budget sans ADR.
- En test, les erreurs « rattrapables » (404, 400…) rendent la page d'erreur simple, pas le rapport détaillé de Rails
  (`consider_all_requests_local = false`) : ce rapport coûtait environ 100 ms par réponse.
- Une system spec suit **un parcours complet** avec plusieurs assertions, plutôt que plusieurs specs qui rejouent chacune la connexion et la navigation.
- Données minimales, `build` / `build_stubbed` quand la base n'est pas nécessaire, pas de `create` en cascade.
- La CI affiche les 10 specs les plus lentes (`--profile 10`) : le relecteur les regarde.

### Pertinents

- Les specs unitaires sont écrites **là où elles apportent quelque chose** : logique métier, branches d'un service, moteur de récurrence, policies, cas limites difficiles à atteindre par le navigateur. Une spec unitaire qui ne fait que redire ce qu'une spec end to end vérifie déjà est inutile.
- On teste le comportement, pas l'implémentation : pas de mock de l'objet testé, pas d'assertion sur des appels internes.

## Outils

| Couche | Outil | Emplacement |
|---|---|---|
| Domaine pur (`Recurrence::*`) | RSpec | `spec/domain/` |
| Services, formulaires, queries | RSpec + FactoryBot | `spec/services/`, `spec/forms/`, `spec/queries/` |
| Modèles | RSpec | `spec/models/` |
| Policies | RSpec + `pundit-matchers` | `spec/policies/` |
| Contrôleurs | Request specs | `spec/requests/` |
| Composants | RSpec + `ViewComponent::TestHelpers` | `spec/components/` |
| Jobs | RSpec (`have_enqueued_job`, `perform_enqueued_jobs`) | `spec/jobs/` |
| Parcours complets | System specs, Capybara + Cuprite | `spec/system/` |
| Stimulus | Vitest + happy-dom | `spec/javascript/` |
| Android natif | JUnit + MockK | projet Android (`android/`) |
| App mobile de bout en bout | Maestro (flux YAML) | projet Android (`android/`) |

## Règles

- **Nouveau code = nouvelle spec.** Un service, une query ou une policy n'est pas terminé sans sa spec unitaire. Un formulaire ou un composant est couvert par sa spec unitaire ou par une spec end to end, selon la logique qu'il contient.
- **Pas de controller specs** : les request specs testent statuts HTTP, redirections, autorisations et effets en base.
- **Services** : tester chaque branche `Success` / `Failure`. Vérifier le résultat monadique (`be_success`, `be_failure`, ou pattern matching), pas les détails d'implémentation.
- **Temps** : toujours `travel_to` (inclure `ActiveSupport::Testing::TimeHelpers`), jamais de dépendance à l'heure réelle.
- **Factories** : minimales et valides par défaut, avec des traits pour les variantes (`:guest`, `:done`, `:overdue`). Éviter les `create` en cascade inutiles, préférer `build` / `build_stubbed` quand la base n'est pas nécessaire.
- **Effets externes** (Firebase, API IA) : toujours derrière un adaptateur, avec un faux adaptateur injecté en test. Aucun appel réseau dans la suite de tests.

## Moteur de récurrence : cas à couvrir

- Récurrence fixe « une semaine sur deux » : continuité sur un changement d'année et sur une année bissextile.
- Échéance sautée ou manquée : une récurrence fixe ne se décale pas, une récurrence glissante repart de la réalisation.
- Récurrence basée sur l'usage : calcul initial, puis recalibrage après un feedback « voyant allumé » et après un feedback « voyant éteint ».
- Fuseau `Indian/Reunion` (UTC+4, sans heure d'été) : une échéance « la veille à 19h » tombe bien le bon jour en UTC.
- Changement des propriétés d'un élément (ex. cycles par semaine) : recalcul de l'intervalle.

## Parcours critiques (system specs obligatoires)

Liste maintenue à jour : une PR qui crée ou modifie un parcours critique l'ajoute ici avec le chemin de sa spec.

| Parcours | Spec | État |
|---|---|---|
| Connexion, déconnexion, mauvais mot de passe | `spec/system/authentication_spec.rb` | Fait |
| Premier foyer à la première connexion, second foyer, changement de foyer | `spec/system/households_spec.rb` | Fait |
| Mot de passe oublié jusqu'à la reconnexion | `spec/system/password_reset_spec.rb` | À faire |
| Ma maison : adresse choisie dans les suggestions, altitude affichée, ajout et suppression d'un emplacement | `spec/system/house_spec.rb` | Fait |
| Ajout rapide d'une plante (photo d'abord, arrosage prérempli à 7 jours, espèce et dernier arrosage repliés), arrosage unique du jour, annulation, intervalle, archivage et restauration | `spec/system/plants_spec.rb` | Fait |
| Tâches d'une plante : ajout (unique, répétée), fait depuis l'accueil et la fiche, annulation, modification, suppression | `spec/system/plant_tasks_spec.rb` | Fait |
| Suivi photo : photo à l'ajout d'une plante (sélecteur en français, datée par l'EXIF), ajout en un geste depuis l'onglet Photos, fichier refusé, galerie par mois, visionneuse sans rechargement (position, flèches, touches du clavier, actions et adresse qui suivent la photo), date corrigée dans sa page, photo de couverture (en tête de fiche, marquée dans la galerie), suppression puis photo suivante | `spec/system/plant_photos_spec.rb` | Fait |
| Analyse : automatique sur la première photo, résumée sur la fiche, puis sélection de photos (la vignette entière se coche) et remarque, résultat affiché, historique | `spec/system/plant_analyses_spec.rb` | Fait |
| Analyse en échec : message visible, relance avec les mêmes photos et la même remarque | `spec/system/plant_analyses_spec.rb` | Fait |
| Discussion sur une analyse : question avec photo jointe, réponse affichée, question suivante avec le fil | `spec/system/plant_analyses_spec.rb` | Fait |
| Propositions d'une analyse acceptées : espèce sur la fiche, intervalle d'arrosage, action devenue tâche | `spec/system/plant_analyses_spec.rb` | Fait |
| Dans l'app Android : sans en-tête web, réglages (bouton natif) et déconnexion | `spec/system/native_app_spec.rb` | Fait |
| Aujourd'hui : tout l'arrosage du jour en un geste, annulé depuis le toast, puis détail par emplacement avec une plante décochée ; « Bientôt » replié | `spec/system/today_spec.rb` | Fait |
| Sections : Aujourd'hui, Maison, Plantes, une plante, puis Journal avec une validation annulée | `spec/system/sections_spec.rb` | Fait |
| Emplacement modifié : analyse signalée à revoir (Maison, Plantes, fiche), relance avec la remarque pré-remplie | `spec/system/location_change_spec.rb` | Fait |
| Dans l'app : actions de la plante dans le menu natif, à jour après un archivage, suppression confirmée ; boutons natifs « Tâche » et « Analyse » de l'onglet Soins ; couverture et suppression d'une photo dans le menu natif | `spec/system/native_app_spec.rb` | Fait |
| Réglages des notifications : résumé coupé, heure, foyers inclus | `spec/system/notification_settings_spec.rb` | Fait |
| Résumé du matin : à l'heure choisie, une fois par jour, rien sans tâche, foyers suivis seulement | `spec/services/notifications/` (le téléphone ne se teste pas en system spec) | Fait |
| Tableau de bord : tâches en retard, du jour, à venir | | Étape 5 |
| Création d'une tâche récurrente : l'échéance apparaît au bon jour | | Étape 5 |
| Validation d'une tâche : journal mis à jour, échéance suivante créée | | Étape 5 |
| Saut d'une échéance | | Étape 5 |
| Ajout d'un élément du catalogue : les tâches sont générées | | Étape 5 |
| Échéance manquée : marquée comme telle par le job, visible dans le journal | | Étape 5 |
| Invité : ne voit et ne valide que ses tâches ouvertes | | Étape 5 |

Les specs système tournent dans un viewport mobile (390 × 844) : l'app est utilisée dans une webview Android.

## Migrations et données existantes

- Une migration qui transforme des données a sa spec : créer les données dans l'ancien format, lancer la migration, vérifier le résultat.
- Le staging rejoue chaque migration sur une copie de la prod : c'est le test d'intégration final, pas un substitut aux specs.
- Les seeds décrivent un foyer réaliste avec de l'historique et sont rejouées en CI.

## Stimulus

Tester avec Vitest uniquement les contrôleurs qui contiennent de la logique (calculs, états). Un contrôleur qui ne fait que basculer une classe CSS est couvert par les system specs.

## Mobile

- Le Kotlin reste mince, donc peu de tests natifs : le gestionnaire de l'action « Fait » d'une notification, le stockage du jeton. Les bridge components sont testés depuis le web : messages en Vitest (`spec/javascript/bridge_components.test.js`), parcours dans un navigateur qui joue l'app (`spec/system/native_app_spec.rb`).
- Maestro : 2 ou 3 tests de fumée (lancement, connexion, validation d'une tâche).
- Notifications push : un bouton « m'envoyer une notification de test » dans les réglages, plus une checklist manuelle avant chaque release.

## CI

`bin/ci` (défini dans `config/ci.rb`) lance en local ce que lance la GitHub Action `.github/workflows/ci.yml` : lint, garde-fous des specs (`bin/check-specs`), audits de sécurité, tests Ruby (dont end to end), tests JavaScript, seeds. Les deux doivent rester alignés.
