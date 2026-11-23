# Décisions d'architecture (ADR)

Une décision structurante = un fichier court : contexte, décision, alternatives écartées, conséquences. On ne réécrit pas l'histoire : si une décision change, on crée un nouvel ADR qui **remplace** l'ancien, et on met à jour le statut de l'ancien.

| # | Décision | Statut |
|---|---|---|
| [0001](0001-rails-hotwire-native.md) | Monolithe Rails + Hotwire Native pour le mobile | Acceptée |
| [0002](0002-esbuild.md) | esbuild pour le JavaScript | Acceptée |
| [0003](0003-solid-queue.md) | Solid Queue plutôt que Redis / Sidekiq | Acceptée |
| [0004](0004-base-de-donnees.md) | PostgreSQL comme base de données | Acceptée |
| [0005](0005-rspec.md) | RSpec pour les tests Ruby | Acceptée |
| [0006](0006-couches-applicatives.md) | Couches : services, formulaires, queries, policies, composants | Acceptée |
| [0008](0008-modele-ia-plantes.md) | Modèle d'IA pour les plantes : forfait Claude via `claude -p`, puis API | Acceptée |
| [0009](0009-adresse-et-altitude.md) | Adresse de la maison : géocodage IGN et altitude Open-Meteo | Acceptée |
| [0010](0010-modele-par-type-et-taches-polymorphes.md) | Un modèle par type d'élément, tâches rattachées par un sujet polymorphe | Acceptée, amendée par 0016 |
| [0011](0011-stockage-des-photos.md) | Stockage des photos : Active Storage sur disque, images normalisées sans métadonnées | Acceptée |
| [0012](0012-notifications-push.md) | Notifications push : résumé du matin par action_push_native et Firebase | Acceptée |
| [0013](0013-identite-visuelle-et-icones.md) | Identité visuelle : palette en jetons Tailwind et icônes Lucide copiées | Acceptée |
| [0014](0014-bridge-components.md) | Bridge components : boutons et menus natifs pilotés par les pages | Acceptée |
| [0015](0015-arrosage-par-la-pluie.md) | La pluie compte comme un arrosage | Acceptée |
| [0016](0016-equipement-generique-et-domaines.md) | Un modèle par domaine qui calcule, un équipement générique pour le reste | Acceptée |
| [0017](0017-rappels-a-heure-fixe.md) | Rappels à heure fixe | Acceptée |

Le numéro 0007 est réservé au flux de livraison (branche `chore/flux-de-livraison`, gelée).

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
