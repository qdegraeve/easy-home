# Stratégie de test

Objectif : un maximum de confiance pour un minimum de lenteur. La majorité des tests sont unitaires et Ruby. Le navigateur et le mobile ne sont testés que sur les parcours critiques.

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

- **Nouveau code = nouvelle spec.** Un service, un formulaire, une query, une policy ou un composant n'est pas terminé sans sa spec.
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

## System specs

Réservées à quelques parcours :

1. Connexion puis tableau de bord des tâches du jour.
2. Ajout d'un élément du catalogue : les tâches sont générées.
3. Validation d'une tâche : le journal est mis à jour et l'échéance suivante créée.
4. Invité : il ne voit que ses tâches ouvertes.

## Stimulus

Tester avec Vitest uniquement les contrôleurs qui contiennent de la logique (calculs, états). Un contrôleur qui ne fait que basculer une classe CSS est couvert par les system specs.

## Mobile

- Le Kotlin reste mince, donc peu de tests natifs : le gestionnaire de l'action « Fait » d'une notification, le stockage du jeton, le parsing des messages des bridge components.
- Maestro : 2 ou 3 tests de fumée (lancement, connexion, validation d'une tâche).
- Notifications push : un bouton « m'envoyer une notification de test » dans les réglages, plus une checklist manuelle avant chaque release.

## CI

`bin/ci` (défini dans `config/ci.rb`) lance lint, audits de sécurité et tests. La GitHub Action `.github/workflows/ci.yml` doit rester alignée.
