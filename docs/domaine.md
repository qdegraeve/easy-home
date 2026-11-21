# Domaine

> **Statut : provisoire.** Ce modèle sert de point de départ et sera affiné en construisant le MVP. Mettre ce fichier à jour à chaque migration qui change le modèle.

## Glossaire

| Français (UI) | Code | Définition |
|---|---|---|
| Foyer | `Household` | La maison et ses occupants. Unité de partage des données. |
| Membre | `HouseholdMember` | Lien entre un utilisateur et un foyer, avec un rôle. |
| Rôle | `HouseholdMember#role` | `owner` (gère le foyer), `member` (voit et fait tout), `guest` (voit uniquement les tâches qui lui sont ouvertes). |
| Élément | `Plant`, plus tard `Pool`, `Dishwasher`… | Ce que possède le foyer. Un modèle et une table par type (ADR 0010). |
| Sujet d'une tâche | `Task#subject` | L'élément auquel une tâche se rattache (polymorphe, optionnel). |
| Modèle de tâche | `TaskTemplate` | Définition dans le catalogue YAML (pas en base). |
| Tâche | `Task` | Une chose à faire de façon récurrente. |
| Échéance | `TaskOccurrence` | Une instance datée d'une tâche. L'ensemble des échéances forme le **journal**. |
| Accès invité | `TaskAccess` | Autorise un membre `guest` à voir et valider une tâche, éventuellement sur une période. |
| Appareil | `ApplicationPushDevice` | Téléphone qui reçoit les notifications : jeton Firebase, rattaché à une session (ADR 0012). |
| Plante | `Plant` | Un élément du foyer : nom, espèce, emplacement. Archivable (`archived_at`). |
| Emplacement | `Location` | Zone de la maison (« terrasse », « jardin devant ») avec son exposition au soleil. |
| Photo | `Photo` | Une photo d'un élément, datée. L'ensemble forme le suivi photo. |
| Analyse | `PlantAnalysis` | Résultat de l'IA sur 1 à 5 photos d'une plante : espèce proposée, état, observations, actions conseillées. |

## Modèle de données (esquisse)

```
User
  has_many :household_members
  has_many :devices

Household
  name, time_zone (défaut "Indian/Reunion")
  address (optionnel)            # libellé choisi dans l'autocomplétion
  latitude, longitude            # issus du géocodage
  altitude_m                     # calculée depuis la position (ADR 0009)
  has_many :members (HouseholdMember), :locations, :plants, :tasks

Location
  household, name
  exposure (full_sun | partial_shade | shade)
  sheltered : boolean            # abrité du vent
  has_many :plants               # nullify à la suppression de l'emplacement

HouseholdMember
  user, household, role (owner | member | guest)
  has_many :task_accesses        # utile pour les guests uniquement

Plant                            # un modèle par type d'élément (ADR 0010)
  household (lecture seule), name
  location (Location, optionnel)
  species, species_source (user | ai)
  archived_at                    # archivée : plus de rappel, journal conservé
  cover_photo (Photo, optionnel) # photo de couverture choisie ; sinon la plus récente (Plant#face)
  has_many :tasks, as: :subject
  has_many :photos

# Plus tard : Pool (volume_m3…), Dishwasher (cycles_per_week…), même principe.

Photo
  plant, taken_at                # date de prise de vue (EXIF, sinon envoi), modifiable
  image (Active Storage)         # JPEG, PNG ou WebP, 15 Mo maximum, validés sur le contenu ;
                                 # stockée normalisée : 2048 px max, JPEG sans métadonnées (ADR 0011)

PlantAnalysis                    # une seule en attente par plante (index unique partiel)
  plant, requested_by (User)
  photos (1 à 5, via PlantAnalysisPhoto)   # la plus récente par défaut
  user_note                      # question ou remarque facultative, transmise à l'IA
  place : jsonb                  # { exposure, sheltered } à la demande, transmis à l'IA ; null avant 2026-11-21
                                 # un lieu différent aujourd'hui signale l'analyse « à revoir »
  status (pending | done | failed), error
  health (ok | watch | act)      # bien / à surveiller / à traiter
  species_name, species_common_name, species_confidence (low | medium | high)
  watering_interval_days         # intervalle proposé (1 à 60), optionnel
  observations : text
  actions : jsonb                # [{ title, details, due_in_days }] ; une action acceptée devient une Task `once`
  applied_action_indexes : int[] # positions des actions déjà devenues tâches (une fois chacune)
  questions (PlantAnalysisQuestion, 10 au plus)

PlantAnalysisQuestion            # question de suivi sur une analyse terminée ; une seule en attente par analyse
  analysis, asked_by (User)
  photo (optionnelle)            # photo jointe, aussi dans le suivi photo de la plante ; supprimée -> null
  body                           # 1 000 caractères au plus
  status (pending | done | failed), answer (texte libre de l'IA), error, model
  model                          # ex. "sonnet"

Task
  household (lecture seule)      # toujours présent : droits et listes passent par lui
  subject (polymorphe, optionnel)  # Plant… ; même foyer que la tâche ; null pour une tâche manuelle
  title, description
  template_key (ex. "plant.watering")
  recurrence_type (once | fixed | sliding | usage_based)
  recurrence_config : jsonb      # paramètres du type de récurrence
  reminder_offset                # quand notifier avant l'échéance (ex. la veille à 19h)
  assignee (HouseholdMember, optionnel)   # prévu pour les tournantes, hors MVP
  active : boolean

TaskOccurrence                   # = une ligne du journal
  task, due_at                   # une seule échéance pending par tâche (index unique partiel)
  notify_at                      # due_at - reminder_offset, indexé pour le planificateur
  status (pending | done | skipped | missed)
  completed_by (User, optionnel), completed_at
  note
  feedback : jsonb               # données de recalibrage (ex. { indicator_on: true })
  notified_at, reminder_count

TaskAccess
  household_member (guest), task
  starts_on, ends_on (optionnels)

ApplicationPushDevice            # gem action_push_native (ADR 0012)
  owner (Session)                # se déconnecter supprime l'appareil
  platform (google), token (unique), name
  # à venir : jeton d'API pour les actions natives (« Fait » depuis une notification), stocké haché

User (réglages des notifications)
  digest_enabled, digest_minute  # résumé du matin : activé, heure en minutes après minuit (quarts d'heure, 5 h-22 h)
  last_digest_on                 # jour du dernier résumé : un seul par jour

HouseholdMember
  digest                         # foyer inclus dans le résumé de ce membre
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
- Un job récurrent (Solid Queue, toutes les 5 minutes) envoie à chacun son **résumé du matin** à l'heure choisie : les
  échéances ouvertes du jour et en retard des foyers suivis, rien les jours sans tâche (ADR 0012). À venir : relances,
  et un job qui marque les échéances `missed`.

## Moteur de récurrence

Ruby pur dans `app/domain/recurrence/`, sans ActiveRecord :

- `Recurrence::Once` : une seule échéance, aucune suivante après réalisation ;
- `Recurrence::Fixed` : règle calendaire, s'appuie sur `ice_cube` ;
- `Recurrence::Sliding` : `interval_days` après la dernière réalisation ;
- `Recurrence::UsageBased` : intervalle = `capacity / usage_per_day`, ajusté par un facteur de calibrage issu du `feedback` des échéances précédentes.

Interface commune : `#next_due_at(last_completed_at:)`, qui renvoie une heure dans le fuseau reçu (`Fixed` ajoutera
ses propres paramètres). Construit depuis `recurrence_type` + `recurrence_config` par une fabrique
(`Recurrence.build(type:, config:)`). Implémentés : `Sliding` (avec `start_on` facultatif, date de la première
échéance) et `Once` (`due_on`). `last_completed_at` vaut nil pour une tâche jamais faite ; `nil` en retour signifie
qu'il n'y a plus d'échéance (tâche unique faite).

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

Ajouter un élément au foyer (`Plants::Add`, plus tard `Pools::Add`…) crée l'élément et instancie les `Task` de son
modèle. Le catalogue n'existe pas encore : il arrivera avec le deuxième type ; `Plants::Add` crée directement sa tâche.

## Plantes

- Une plante porte une seule tâche, `plant.watering`, en récurrence **glissante**, créée à l'ajout avec l'intervalle
  saisi (1 à 60 jours). L'analyse propose de le remplacer (`watering_interval_days`) ; il reste modifiable à la main.
  Une analyse en échec ou en attente ne bloque donc rien.
- À l'ajout, le « dernier arrosage » (aujourd'hui par défaut) entre au journal et sert de point de départ à la première
  échéance. Changer l'intervalle recale l'échéance ouverte depuis le dernier arrosage.
- Une plante peut avoir des **tâches manuelles** (engrais, taille…) : une seule fois à une date (`once`), ou tous les
  N jours après la dernière fois à partir d'une première date (`sliding` avec `start_on`). Elles se modifient (titre,
  date de la prochaine fois, intervalle) et se suppriment ; la tâche d'arrosage se règle depuis la plante. Une tâche
  unique faite disparaît de la fiche et reste au journal.
- L'accueil liste **« À faire aujourd'hui »** : toutes les échéances ouvertes dues aujourd'hui ou en retard, arrosages
  et autres tâches.
- Une tâche ne se fait qu'une fois par jour (`Tasks::Complete`) : un second « Arrosée » le même jour est refusé.
- Une réalisation enregistrée par erreur s'annule depuis le journal (`Tasks::CancelCompletion`) : elle disparaît et
  l'échéance ouverte est recalculée depuis la réalisation précédente.
- Archiver une plante désactive sa tâche et supprime l'échéance ouverte ; restaurer la recalcule depuis le dernier
  arrosage.
- Ajouter une plante avec une photo : création de la `Plant` et de sa première `Photo`, puis analyse en job.
- Les propositions d'une analyse terminée s'acceptent une à une, par un bouton (plante non archivée) :
  - l'espèce (`Plants::AcceptSpecies`) remplit `species` avec le nom scientifique et `species_source: ai` ; corrigée
    ensuite à la main, elle passe en `species_source: user` ;
  - l'intervalle (`Plants::AcceptWatering`) remplace celui de la tâche d'arrosage et recale l'échéance ouverte depuis
    le dernier arrosage ;
  - une action (`Plants::AcceptAction`) devient une `Task` en récurrence `once`, due `due_in_days` jours après la fin
    de l'analyse (aujourd'hui si cette date est passée), une seule fois par action.
  L'espèce et l'intervalle s'affichent comme acceptés tant que la plante y correspond ; une action, dès qu'elle est
  devenue tâche (même supprimée ensuite).
- Sous une analyse terminée, une **discussion** : on pose une question (`Plants::AskQuestion`), avec une photo jointe
  facultative qui rejoint le suivi photo ; l'IA répond en texte libre dans un job (`AnswerQuestionJob`), la page se
  met à jour seule. Une question à la fois, 10 au plus par analyse ; une réponse en échec se redemande
  (`Plants::AskAgain`).
- Chaque analyse reçoit le contexte : position arrondie (environ 1 km) et altitude du foyer, exposition et abri de
  l'emplacement, espèce confirmée, intervalle d'arrosage actuel, mois en cours (saisons de l'hémisphère sud).
  **L'adresse n'est jamais envoyée à l'IA**, ni les métadonnées de la photo (voir ADR 0008), et ces données restent en
  base, jamais dans le dépôt.
- Une analyse ne modifie jamais rien d'elle-même : l'espèce, l'intervalle et les actions sont des **propositions** à
  accepter. Le fournisseur d'IA est derrière `PlantAnalyzer` (ADR 0008).
