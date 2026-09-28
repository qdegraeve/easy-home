# Décisions d'architecture (ADR)

Une décision structurante = un fichier court : contexte, décision, alternatives écartées, conséquences. On ne réécrit pas l'histoire : si une décision change, on crée un nouvel ADR qui **remplace** l'ancien, et on met à jour le statut de l'ancien.

| # | Décision | Statut |
|---|---|---|
| [0001](0001-rails-hotwire-native.md) | Monolithe Rails + Hotwire Native pour le mobile | Acceptée |
| [0002](0002-esbuild.md) | esbuild pour le JavaScript | Acceptée |
| [0003](0003-solid-queue.md) | Solid Queue plutôt que Redis / Sidekiq | Acceptée |
| [0004](0004-base-de-donnees.md) | PostgreSQL comme base de données | Acceptée |
| [0005](0005-rspec.md) | RSpec pour les tests Ruby | Acceptée (installation à faire) |
| [0006](0006-couches-applicatives.md) | Couches : services, formulaires, queries, policies, composants | Acceptée |

## Modèle

```markdown
# NNNN. Titre

- Statut : proposée | acceptée | remplacée par NNNN
- Date : AAAA-MM-JJ

## Contexte
## Décision
## Alternatives écartées
## Conséquences
```
