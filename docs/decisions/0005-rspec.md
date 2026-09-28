# 0005. RSpec pour les tests Ruby

- Statut : acceptée (installation à faire, l'app est encore générée avec Minitest)
- Date : 2026-09-28

## Contexte

Le développeur maîtrise RSpec. L'app doit être testable couche par couche, y compris les composants et les policies.

## Décision

- **Ruby** : RSpec + FactoryBot + shoulda-matchers + pundit-matchers.
- **Contrôleurs** : request specs (pas de controller specs).
- **Parcours de bout en bout** : system specs Capybara + Cuprite, en nombre limité.
- **Stimulus** : Vitest + happy-dom, uniquement pour les contrôleurs qui contiennent de la logique.
- **Android** : JUnit + MockK pour le peu de Kotlin, et Maestro pour 2 ou 3 tests de fumée.

## Alternatives écartées

- **Minitest + fixtures** (défaut Rails) : plus léger et plus rapide, mais moins familier au développeur.
- **Jest** : plus lourd à configurer en ESM que Vitest.

## Conséquences

- Supprimer `test/` et adapter `config/ci.rb` ainsi que la GitHub Action.
- Détails dans `docs/tests.md`.
