# Domaine

> **Statut : provisoire.** Ce modèle sert de point de départ et sera affiné en construisant le MVP. Mettre ce fichier à jour à chaque migration qui change le modèle.

## Glossaire

| Français (UI) | Code | Définition |
|---|---|---|
| Foyer | `Household` | La maison et ses occupants. Unité de partage des données. |
| Membre | `Membership` | Lien entre un utilisateur et un foyer, avec un rôle. |
| Rôle | `Membership#role` | `owner` (gère le foyer), `member` (voit et fait tout), `guest` (voit uniquement les tâches qui lui sont ouvertes). |
| Élément | `Item` | Ce que possède le foyer : équipement, animal, bassin, plante… |
| Type d'élément | `Item#kind` | Clé du catalogue (`dishwasher`, `pool`, `cat`, `trash_bins`…). |
| Modèle de tâche | `TaskTemplate` | Définition dans le catalogue YAML (pas en base). |
| Tâche | `Task` | Une chose à faire de façon récurrente. |
| Échéance | `TaskOccurrence` | Une instance datée d'une tâche. L'ensemble des échéances forme le **journal**. |
| Accès invité | `TaskAccess` | Autorise un membre `guest` à voir et valider une tâche, éventuellement sur une période. |
| Appareil | `Device` | Téléphone d'un utilisateur : jeton push Firebase et jeton d'API natif. |

## Modèle de données (esquisse)

```
User
  has_many :memberships
  has_many :devices

Household
  name, time_zone (défaut "Indian/Reunion")
  has_many :memberships, :items, :tasks

Membership
  user, household, role (owner | member | guest)
  has_many :task_accesses        # utile pour les guests uniquement

Item
  household, kind, name
  properties : jsonb             # attributs variables : cycles_per_week, volume_m3…

Task
  household
  item (optionnel)               # null pour une tâche manuelle indépendante
  title, description
  source (manual | template), template_key (ex. "dishwasher.salt")
  recurrence_type (fixed | sliding | usage_based)
  recurrence_config : jsonb      # paramètres du type de récurrence
  reminder_offset                # quand notifier avant l'échéance (ex. la veille à 19h)
  assignee (Membership, optionnel)   # prévu pour les tournantes, hors MVP
  active : boolean

TaskOccurrence                   # = une ligne du journal
  task, due_at
  notify_at                      # due_at - reminder_offset, indexé pour le planificateur
  status (pending | done | skipped | missed)
  completed_by (User, optionnel), completed_at
  note
  feedback : jsonb               # données de recalibrage (ex. { indicator_on: true })
  notified_at, reminder_count

TaskAccess
  membership (guest), task
  starts_on, ends_on (optionnels)

Device
  user, platform (android), push_token
  api_token_digest               # jeton d'API pour les actions natives, stocké haché
  last_seen_at
```

## Cycle de vie d'une échéance

```
pending ──(Fait)──────────▶ done
   │  └──(Sauter)─────────▶ skipped
   └──(délai de grâce dépassé)──▶ missed
```

- À chaque passage en `done` ou `skipped`, la tâche calcule sa prochaine échéance via le moteur de récurrence et crée la `TaskOccurrence` suivante.
- Une récurrence **fixe** se cale sur le calendrier : sauter ou rater une échéance ne décale pas la suivante.
- Une récurrence **glissante** ou **basée sur l'usage** part de la date de réalisation.
- Un job récurrent (Solid Queue, toutes les minutes) envoie les notifications arrivées à échéance et gère les relances. Un autre marque les échéances `missed`.

## Moteur de récurrence

Ruby pur dans `app/domain/recurrence/`, sans ActiveRecord :

- `Recurrence::Fixed` : règle calendaire, s'appuie sur `ice_cube` ;
- `Recurrence::Sliding` : `interval_days` après la dernière réalisation ;
- `Recurrence::UsageBased` : intervalle = `capacity / usage_per_day`, ajusté par un facteur de calibrage issu du `feedback` des échéances précédentes.

Interface commune : `#next_due_at(from:, last_completed_at:)`. Construit depuis `recurrence_type` + `recurrence_config` par une fabrique (`Recurrence.build(task)`).

## Catalogue de modèles de tâches

Fichiers YAML versionnés dans `config/task_templates/`, un par type d'élément. Chargés au démarrage, pas de table en base.

```yaml
# config/task_templates/dishwasher.yml
kind: dishwasher
properties:
  cycles_per_week: { type: integer, default: 5 }
tasks:
  - key: dishwasher.salt
    title: Remettre du sel régénérant
    recurrence:
      type: usage_based
      capacity: 40                      # cycles
      usage_rate: cycles_per_week       # propriété de l'élément
    feedback_question: Le voyant « sel » était-il allumé ?
  - key: dishwasher.filter
    title: Nettoyer le filtre
    recurrence: { type: sliding, interval_days: 30 }
```

Ajouter un élément au foyer (`Items::Add`) crée l'`Item` et instancie les `Task` de son modèle.
