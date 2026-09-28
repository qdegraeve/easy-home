# Easy Home

Application de gestion de la maison : rappels des tâches domestiques (poubelles, piscine, animaux, entretien des équipements), notifications push au bon moment et journal des tâches faites ou manquées.

Side project à usage privé (le foyer du développeur) et terrain d'exploration de **Hotwire Native**. Point de départ : ne plus oublier la poubelle jaune, collectée une semaine sur deux.

**Langues** : documentation et interface en français. Code (classes, méthodes, tables, colonnes) en anglais.

## Documentation

Lire le document concerné avant toute tâche qui touche son sujet.

| Fichier | Contenu |
|---|---|
| `docs/produit.md` | Vision, périmètre du MVP, ce qui est hors MVP |
| `docs/domaine.md` | Glossaire et modèle de données (provisoire) |
| `docs/architecture.md` | Couches applicatives, règles d'usage, exemples de code |
| `docs/tests.md` | Stratégie de test par couche |
| `docs/hotwire-native.md` | App Android, notifications push, authentification native, déploiement |
| `docs/roadmap.md` | Étapes de construction et setup restant |
| `docs/decisions/` | ADR : décisions structurantes et leur justification |

## Stack

- Ruby 4.0.7, Rails 8.1.4, Node 22.18.0, Yarn
- Base de données : PostgreSQL 18 (ADR 0004). Colonnes JSON en `jsonb`
- Hotwire (Turbo + Stimulus) ; JS bundlé par esbuild (`jsbundling-rails`) ; Tailwind CSS 4 (`cssbundling-rails`) ; Propshaft
- Solid Queue, Solid Cache, Solid Cable (pas de Redis). En production, Solid Queue tourne dans Puma (`SOLID_QUEUE_IN_PUMA`)
- Déploiement : Kamal + Thruster
- À venir : Hotwire Native Android (Kotlin), notifications via Firebase Cloud Messaging

## Commandes

```bash
bin/setup                # installation initiale
bin/dev                  # serveur web + build JS + build CSS en watch
bin/ci                   # CI locale complète (lint, audits, tests)
bin/rubocop -a           # lint avec correction automatique
bin/brakeman             # analyse de sécurité
bin/jobs                 # worker Solid Queue en local
bundle exec rspec        # tests Ruby (une fois RSpec installé, voir roadmap)
yarn test                # tests JS Vitest (une fois installé)
```

## Architecture : règles essentielles

Détails et exemples dans `docs/architecture.md`. Principe directeur : **une structure claire et testable, sans abstraction spéculative**. On n'ajoute une couche que lorsqu'un besoin concret la justifie.

- **Contrôleurs minces** : authentifier, autoriser, appeler un service (ou faire un CRUD simple), rendre ou rediriger. Le résultat d'un service est traité par pattern matching (`case ... in Success(...)`).
- **Modèles** : associations, scopes simples, validations d'invariants. **Pas de callbacks à effets de bord** (notification, job, appel externe) : ça va dans un service.
- **Services** (`app/services/<domaine>/<verbe>.rb`, ex. `Tasks::Complete`) : uniquement si l'action touche plusieurs modèles ou déclenche des effets de bord. `Dry::Monads` (Result + do notation), méthode publique unique `#call` avec arguments nommés, retour `Success(valeur)` ou `Failure[:code, payload]`.
- **Formulaires / contrats** (`app/forms`) : `ActiveModel::Validations` + `SimpleDelegator` quand la validation dépend du contexte ou couvre plusieurs modèles. Compatibles avec `form_with`.
- **Query objects** (`app/queries`) : requêtes réutilisées ou non triviales. Retournent une relation ActiveRecord composable. Les requêtes simples restent des scopes.
- **Policies** (`app/policies`, Pundit) : toute lecture de collection passe par `policy_scope`, toute action par `authorize`. Indispensable pour les invités aux droits restreints.
- **Composants** (`app/components`, ViewComponent) : UI réutilisée ou avec de la logique d'affichage. Les partials restent pour la mise en page propre à une page et les templates turbo_stream.
- **Domaine pur** (`app/domain`) : Ruby pur sans ActiveRecord, notamment le moteur de récurrence (`Recurrence::*`).
- **Jobs minces** : ils délèguent à un service.

## Conventions

- Aucun texte en dur dans les vues : I18n avec `config/locales/fr.yml`.
- Fuseau horaire de l'utilisateur : `Indian/Reunion`. Toujours `Time.current` / `Date.current`, jamais `Time.now`. Stockage en UTC.
- Style : `rubocop-rails-omakase`.
- Pas de nouvelle gem ou paquet npm sans justification. Un choix structurant donne lieu à un ADR dans `docs/decisions/`.
- Le Kotlin de l'app Android reste de la plomberie : la logique métier vit dans Rails.

## Tests

Détails dans `docs/tests.md`.

- RSpec + FactoryBot. Request specs plutôt que controller specs.
- Tout service, formulaire, query, policy et composant a sa spec unitaire.
- Le moteur de récurrence est testé de façon exhaustive, avec `travel_to` pour figer le temps.
- System specs (Capybara + Cuprite) réservées à quelques parcours critiques.
- Stimulus : Vitest uniquement pour les contrôleurs qui contiennent de la logique.

## État actuel

L'app vient d'être générée : aucun code métier. Le setup n'est pas terminé (passage à PostgreSQL fait, mais Minitest encore en place, gems d'architecture pas encore ajoutées, pas d'authentification). Voir la checklist dans `docs/roadmap.md`. **Vérifier le `Gemfile` avant de supposer qu'une gem citée ici est installée.**

## Façon de travailler

- Pour une tâche non triviale, proposer un plan court avant de coder.
- Avant d'annoncer une tâche terminée : lancer `bin/rubocop` et les tests concernés.
- Quand une décision change, mettre à jour l'ADR et la doc concernée dans le même changement.
