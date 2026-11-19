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
| Plante | `Item` (`kind: plant`) | Un élément du foyer. Espèce dans `properties`. |
| Emplacement | `Location` | Zone de la maison (« terrasse », « jardin devant ») avec son exposition au soleil. |
| Photo | `Photo` | Une photo d'un élément, datée. L'ensemble forme le suivi photo. |
| Analyse | `PhotoAnalysis` | Résultat de l'IA sur une photo : espèce proposée, état, observations, actions conseillées. |

## Modèle de données (esquisse)

```
User
  has_many :memberships
  has_many :devices

Household
  name, time_zone (défaut "Indian/Reunion")
  address (optionnel)            # libellé choisi dans l'autocomplétion
  latitude, longitude            # issus du géocodage
  altitude_m                     # calculée depuis la position (ADR 0009)
  has_many :memberships, :items, :tasks, :locations

Location
  household, name
  exposure (full_sun | partial_shade | shade)
  sheltered : boolean            # abrité du vent
  has_many :items

Membership
  user, household, role (owner | member | guest)
  has_many :task_accesses        # utile pour les guests uniquement

Item
  household, kind, name
  location (Location, optionnel)
  properties : jsonb             # attributs variables : cycles_per_week, volume_m3…
                                 # plante : { species, species_source (ai | user) }
  has_many :photos

Photo
  item, taken_at
  image (Active Storage)         # JPEG, PNG ou WebP, 15 Mo maximum, validés sur le contenu
  has_one :analysis (PhotoAnalysis)

PhotoAnalysis
  photo
  status (pending | done | failed), error
  health (ok | watch | act)      # bien / à surveiller / à traiter
  species_guess, species_confidence
  watering_interval_days         # intervalle proposé (1 à 60), optionnel
  observations : text
  actions : jsonb                # [{ title, details, due_in_days }] ; une action acceptée devient une Task `once`
  provider                       # ex. "claude_cli"

Task
  household
  item (optionnel)               # null pour une tâche manuelle indépendante
  title, description
  source (manual | template), template_key (ex. "dishwasher.salt")
  recurrence_type (once | fixed | sliding | usage_based)
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

## Foyers et comptes

- Un compte est créé en console (`bin/rails accounts:create`), sans inscription publique. Le foyer se crée ensuite
  dans l'app : un utilisateur sans foyer est envoyé vers « Créer un foyer » (`Households::Create`, rôle `owner`).
- Un utilisateur peut avoir plusieurs foyers. Le **foyer actif** est mémorisé en session (`session[:household_id]`) et
  se change depuis « Mes foyers ». À défaut, ou si la session pointe vers un foyer dont il n'est plus membre, c'est son
  premier foyer par ordre alphabétique. Toute lecture passe par `policy_scope(Household)`.

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

- `Recurrence::Once` : une seule échéance, aucune suivante après réalisation ;
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

## Plantes

- Le modèle `plant` du catalogue porte une seule tâche, `plant.watering`, en récurrence **glissante**, créée à l'ajout
  de la plante avec un intervalle par défaut du catalogue (3 jours). L'analyse propose de le remplacer
  (`watering_interval_days`) ; il reste modifiable à la main. Une analyse en échec ou en attente ne bloque donc rien.
- Une action conseillée acceptée devient une `Task` en récurrence `once`, due dans `due_in_days` jours.
- Ajouter une plante : création de l'`Item` et de sa première `Photo`, puis analyse en job. L'espèce proposée s'affiche
  à confirmer : acceptée telle quelle, elle remplit `properties.species` avec `species_source: ai` ; corrigée, avec
  `species_source: user`.
- Chaque analyse reçoit le contexte : position arrondie (environ 1 km) et altitude du foyer, exposition et abri de
  l'emplacement, espèce confirmée, intervalle d'arrosage actuel, mois en cours (saisons de l'hémisphère sud).
  **L'adresse n'est jamais envoyée à l'IA**, ni les métadonnées de la photo (voir ADR 0008), et ces données restent en
  base, jamais dans le dépôt.
- Une analyse ne modifie jamais rien d'elle-même : l'espèce, l'intervalle et les actions sont des **propositions** à
  accepter. Le fournisseur d'IA est derrière `Plants::Analyzer` (ADR 0008).
