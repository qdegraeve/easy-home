# Easy Home

Application de gestion de la maison : rappels des tâches domestiques (poubelles, piscine, animaux, entretien des équipements), notifications push au bon moment et journal des tâches faites ou manquées.

Side project à usage privé (le foyer du développeur) et terrain d'exploration de **Hotwire Native**. Point de départ : ne plus oublier la poubelle jaune, collectée une semaine sur deux.

**Langues** : documentation et interface en français. Code (classes, méthodes, tables, colonnes) en anglais.

> **Dépôt public.** Aucun secret, aucune IP, aucun domaine réel, aucune donnée du foyer ou de la prod dans le code, les specs, les commits ou les PR.

## Documentation

Lire le document concerné avant toute tâche qui touche son sujet.

| Fichier | Contenu |
|---|---|
| `docs/produit.md` | Vision, périmètre du MVP, ce qui est hors MVP |
| `docs/domaine.md` | Glossaire et modèle de données (provisoire) |
| `docs/architecture.md` | Couches applicatives, règles d'usage, exemples de code |
| `docs/tests.md` | Exigences de test, stratégie par couche, parcours critiques |
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
bundle exec rspec        # tests Ruby, dont end to end (yarn build && yarn build:css avant les system specs)
yarn test                # tests JS Vitest
bin/check-specs          # garde-fous des specs : pas de sleep, de focus, de retry, de Time.now
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

**Les tests sont la preuve que l'application fonctionne : personne ne relit le code.** Exigences complètes dans `docs/tests.md`, à lire avant d'écrire une spec.

- **Tous les parcours critiques sont testés de bout en bout** (system specs Capybara + Cuprite), du geste de l'utilisateur au résultat visible. Liste dans `docs/tests.md`, à tenir à jour.
- **Chaque critère d'acceptation du ticket est couvert par une spec**, citée dans la PR.
- **Fiables** : attendre un état (matchers Capybara, `have_no_*`), jamais une durée ; `travel_to` ; aucune dépendance au réseau ou à l'ordre. Une spec instable se corrige, elle ne se relance pas.
- **Rapides** : budget par spec appliqué en CI (1 s, 8 s pour une spec système). Données minimales, un parcours complet par system spec.
- **Pertinents** : specs unitaires là où elles apportent quelque chose (logique métier, services, récurrence, policies, cas limites). Pas de spec qui recopie l'implémentation.
- RSpec + FactoryBot. Request specs plutôt que controller specs. Stimulus : Vitest pour les contrôleurs qui contiennent de la logique.
- Le moteur de récurrence est testé de façon exhaustive.
- Migrations : compatibles avec les données existantes ; une transformation de données a sa spec.

## État actuel

L'app vient d'être générée : aucun code métier. Le setup n'est pas terminé (passage à PostgreSQL fait, mais Minitest encore en place, gems d'architecture pas encore ajoutées, pas d'authentification). Voir la checklist dans `docs/roadmap.md`. **Vérifier le `Gemfile` avant de supposer qu'une gem citée ici est installée.**

## Façon de travailler

- Pour une tâche non triviale, proposer un plan court avant de coder.
- Avant d'annoncer une tâche terminée ou de pousser : `bin/ci` entièrement vert.
- Quand une décision change, mettre à jour l'ADR et la doc concernée dans le même changement.
