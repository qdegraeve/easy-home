# Domaine

> **Statut : provisoire.** Ce modèle sert de point de départ et sera affiné en construisant le MVP. Mettre ce fichier à jour à chaque migration qui change le modèle.

## Glossaire

| Français (UI) | Code | Définition |
|---|---|---|
| Foyer | `Household` | La maison et ses occupants. Unité de partage des données. |
| Membre | `HouseholdMember` | Lien entre un utilisateur et un foyer, avec un rôle. |
| Rôle | `HouseholdMember#role` | `manager` (gestionnaire : règle le foyer, et bientôt ses membres ; plusieurs par foyer, ADR 0019), `member` (voit et fait tout : plantes, équipements, tâches, emplacements), `guest` (voit uniquement les tâches des sujets qui lui sont ouverts). |
| Domaine qui calcule | `Plant`, plus tard `Pet` | Ce dont l'app exploite les attributs : un modèle et une table par domaine (ADR 0010, 0016). |
| Équipement | `Equipment` | Ce qu'on entretient et dont l'app rappelle les tâches (piscine, lave-vaisselle, chauffe-eau…) : nom, type, « À savoir », photos. Générique (ADR 0016). |
| Sujet d'une tâche | `Task#subject` | La plante ou l'équipement auquel une tâche se rattache (polymorphe) ; nul pour une **tâche de la maison** (poubelles). |
| Suggestion | `config/catalogue.yml`, `Catalogue` | Tâche toute prête d'un type d'équipement ou de la maison, copiée dans la tâche à sa création (pas en base). |
| Tâche | `Task` | Une chose à faire, une fois ou de façon répétée. |
| Comment faire | `Task#instructions` | Le mode opératoire d'une tâche, lu au moment de la faire, dans sa feuille. |
| À savoir | `Equipment#notes` | Ce qu'on sait d'un équipement hors tâche (référence du filtre, garantie…). |
| Échéance | `TaskOccurrence` | Une instance datée d'une tâche. L'ensemble des échéances forme le **journal**. |
| Accès invité | `GuestAccess` | Ouvre un sujet (plante, équipement, ou le foyer pour les tâches de la maison) et toutes ses tâches à un `guest`, pendant sa période (ADR 0019). |
| Invitation | `Invitation` | Lien à usage unique qui donne à une personne la place réservée pour elle dans le foyer (ADR 0019). |
| Appareil | `ApplicationPushDevice` | Téléphone qui reçoit les notifications : jeton Firebase, rattaché à une session (ADR 0012). |
| Plante | `Plant` | Un élément du foyer : nom, espèce, emplacement. Archivable (`archived_at`). |
| Emplacement | `Location` | Zone de la maison (« terrasse », « jardin devant ») avec son exposition au soleil. |
| Photo | `Photo` | Une photo d'un élément, datée. L'ensemble forme le suivi photo. |
| Analyse | `PlantAnalysis` | Résultat de l'IA sur 1 à 5 photos d'une plante : espèce proposée, état, observations, actions conseillées. |

## Modèle de données (esquisse)

```
User
  email, name (prénom affiché aux autres membres ; à défaut, le début de l'e-mail : « sam.dupont@… » donne « Sam »)
  has_many :household_members
  has_many :devices

Household
  name, time_zone (défaut "Indian/Reunion")
  address (optionnel)            # libellé choisi dans l'autocomplétion
  latitude, longitude            # issus du géocodage
  altitude_m                     # calculée depuis la position (ADR 0009)
  has_many :members (HouseholdMember), :locations, :plants, :tasks, :rainfalls

Rainfall                         # pluie du jour au foyer, relevée le soir (ADR 0015)
  household, on (date, unique par foyer), millimeters

Location
  household, name
  exposure (full_sun | partial_shade | shade)
  sheltered : boolean            # abrité du vent
  rain_exposed : boolean         # reçoit la pluie (décoché par défaut) : la pluie y arrose les plantes (ADR 0015)
  has_many :plants               # nullify à la suppression de l'emplacement

HouseholdMember
  user, household, role (manager | member | guest)
  user (nul : place réservée par une invitation, sans aucun droit), invitee_name (« Pour qui ? »)
  has_one :invitation
  guest_full_access              # « Tout ouvrir » : tout le foyer, y compris ce qui sera ajouté
  access_starts_on, access_ends_on   # période de l'invité, facultatives ; hors période, rien
  has_many :guest_accesses

Plant                            # un modèle par type d'élément (ADR 0010)
  household (lecture seule), name
  location (Location, optionnel)
  species, species_source (user | ai)
  archived_at                    # archivée : plus de rappel, journal conservé
  cover_photo (Photo, optionnel) # photo de couverture choisie ; sinon la plus récente (Plant#face)
  has_many :tasks, as: :subject
  has_many :photos

Equipment                        # générique, pas de champ propre à un type (ADR 0016)
  household (lecture seule), kind (liste du catalogue, « other » = personnalisé), name (le type si vide)
  notes : text                   # « À savoir »
  has_many :tasks, as: :subject ; has_many :photos, as: :subject   # suppression : tâches et journal effacés

Photo
  subject (polymorphe : Plant, Equipment, Task)   # requis en base ; ancienne colonne plant_id ignorée, supprimée ensuite
  taken_at                       # date de prise de vue (EXIF, sinon envoi), modifiable
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
  subject (polymorphe, optionnel)  # Plant, Equipment ; même foyer que la tâche ; null : tâche de la maison
  title
  instructions : text            # « Comment faire » (5 000 caractères au plus), lu dans la feuille de la tâche
  template_key (ex. "plant.watering")   # tâche gérée par son sujet (réglée depuis la plante)
  suggestion_key                 # suggestion d'origine (ex. "bins.yellow"), sans comportement
  importance (flexible | critical)   # souple (défaut, arrosage) ou « à ne pas rater » : en tête, en rouge, sans marge
  recurrence_type (once | sliding | fixed | on_demand)   # modifiable
  recurrence_config : jsonb      # paramètres du type de récurrence
  reminder_minute                # rappel le jour de l'échéance, minutes après minuit, 5 h à 22 h au quart d'heure
                                 # (ADR 0017) ; nul : le résumé du matin seulement
  active : boolean

TaskOccurrence                   # = une ligne du journal
  task, due_at                   # une seule échéance pending par tâche (index unique partiel)
  status (pending | done | missed | postponed)
  completed_by (User, optionnel), completed_at
  source (manual | rain)         # fermée par une personne ou par la pluie (sans auteur, ADR 0015)
  reopened_after_miss : boolean  # rouverte après un oubli : plus jamais manquée
  reminders_sent, last_reminded_at   # rappels envoyés pour cette échéance et le dernier (ADR 0017)

GuestAccess                      # ADR 0019 ; lu par GuestVisibilityQuery, elle-même lue par les policies
  household_member (guest), subject (Plant, Equipment, ou Household pour les tâches de la maison)

Invitation                       # ADR 0019 : lien à usage unique, 7 jours ; expirée, sa place est supprimée la nuit
  household_member (la place réservée), created_by (User), token_digest (SHA-256), expires_at, accepted_at

ApplicationPushDevice            # gem action_push_native (ADR 0012)
  owner (Session)                # se déconnecter supprime l'appareil
  platform (google), token (unique), name
  # à venir : jeton d'API pour les actions natives (« Fait » depuis une notification), stocké haché

User (réglages des notifications)
  digest_enabled, digest_minute  # résumé du matin : activé, heure en minutes après minuit (quarts d'heure, 5 h-22 h)
  digest_scope (all | critical)  # tout, ou seulement les tâches « à ne pas rater »
  last_digest_on                 # jour du dernier résumé : un seul par jour

HouseholdMember
  digest                         # foyer inclus dans le résumé de ce membre
```

## Foyers et comptes

- Un compte est créé en console (`bin/rails accounts:create`), sans inscription publique. Le foyer se crée ensuite
  dans l'app : un utilisateur sans foyer est envoyé vers « Créer un foyer » (`Households::Create`, rôle `manager`).
- Membres (ADR 0019, `Members::ChangeRole`, `Members::Remove`) : un gestionnaire change un rôle (membre ↔
  gestionnaire) et retire quelqu'un ; chacun quitte un foyer depuis « Mes foyers ». Un foyer garde toujours un
  gestionnaire (sous verrou du foyer). Retirer ne supprime ni le compte ni ses lignes du journal.
- Un utilisateur peut avoir plusieurs foyers. Le **foyer actif** est mémorisé en session (`session[:household_id]`) et
  se change depuis « Mes foyers ». À défaut, ou si la session pointe vers un foyer dont il n'est plus membre, c'est son
  premier foyer par ordre alphabétique. Toute lecture passe par `policy_scope(Household)`.

## Cycle de vie d'une échéance

```
pending ──(Fait)──────────▶ done
   │  └──(Reporter)───────▶ postponed   (+ la même tâche ouverte le lendemain)
   └──(délai de grâce dépassé)──▶ missed
```

- **Tolérance** (`Tolerance`, `app/domain`) : une tâche « à ne pas rater » n'en a aucune, elle est manquée le
  lendemain de son jour. Une tâche souple répétée a une marge d'un quart de son intervalle, de 0 à 3 jours (1 jour : 0,
  3 jours : 1, 7 jours : 2, 14 jours : 3). Une tâche unique souple n'est jamais manquée : elle reste à faire jusqu'à
  ce qu'elle soit faite ou supprimée.
- `Tasks::MarkMissed` (job toutes les heures) ferme en `missed` les échéances au-delà de leur marge : une ligne du
  journal, **une seule par échéance**, `completed_at` étant le moment de la fermeture. Une tâche glissante reste à faire
  : elle est rouverte avec la même échéance (« prévu il y a 5 j »), marquée `reopened_after_miss`, et n'est plus jamais
  manquée jusqu'à ce qu'elle soit faite. Une tâche unique manquée est terminée, comme une fois faite.
- Une date calculée par l'app (recalcul, plante restaurée, ajout avec un vieil arrosage, date saisie dans le passé)
  ne part jamais au-delà de la marge (`Tolerance.earliest`) : rien n'est manqué d'emblée. Une échéance déplacée perd
  `reopened_after_miss` et peut de nouveau être manquée, une fois.
- « Fait » appuyé sur une page affichée avant le passage du job valide la tâche rouverte.
- **Décaler** (`Tasks::Postpone`, bouton « Reporter » d'une ligne d'« Aujourd'hui ») : une échéance due ou en retard
  est fermée en `postponed` (une ligne discrète du journal, « Échéance reportée », ni faite ni manquée) et la même
  tâche est ouverte le lendemain. La récurrence n'est pas touchée : elle part toujours de la dernière réalisation.
  « Annuler » dans le toast défait le décalage (`Tasks::CancelPostponement`) tant que la tâche n'a pas été faite. Un
  recalcul ne revient jamais avant le lendemain d'un décalage postérieur à la dernière réalisation. Décaler une tâche
  rouverte après un oubli en fait une nouvelle échéance, qui peut de nouveau être manquée, une fois. Pas de « Reporter »
  sur la ligne groupée « Arroser · N » pour l'instant (question ouverte).
- **Pluie** (`Plants::RecordRain`, job chaque soir à 22 h, ADR 0015) : pour les plantes d'un emplacement qui reçoit
  la pluie, les arrosages dus au plus tard le lendemain sont notés faits par la pluie à partir de 10 mm sur la journée
  (le suivant repart de ce jour), décalés d'un jour de 3 à 10 mm, inchangés en dessous. Mêmes services et même verrou
  que les gestes de l'utilisateur (`source: :rain`) ; une validation par la pluie s'annule comme une autre.

- À chaque passage en `done`, la tâche calcule sa prochaine échéance via le moteur de récurrence et crée la
  `TaskOccurrence` suivante.
- Une récurrence **glissante** part de la date de réalisation. Une récurrence **à jour fixe** se cale sur sa règle :
  faite en avance, à l'heure, en retard ou reportée, la suivante est la première date de la règle après la dernière
  échéance (après un oubli, selon l'importance, voir « Moteur de récurrence »). Une tâche **quand il le faut** n'a
  jamais d'échéance ouverte.
- Un job récurrent (Solid Queue, toutes les 5 minutes) envoie à chacun son **résumé du matin** à l'heure choisie : les
  échéances ouvertes du jour et en retard des foyers suivis, rien les jours sans tâche (ADR 0012). Groupé comme
  l'écran : les tâches « à ne pas rater » d'abord, tous les arrosages en un élément (« arroser 4 plantes »), puis le
  reste ; ou seulement les « à ne pas rater » si l'utilisateur le choisit. Une tâche avec un rappel y dit quand :
  « ce soir 19 h : sortir la poubelle jaune ».
- **Rappels** (ADR 0017, `SendRemindersJob` toutes les 5 minutes, `RemindersDueQuery`, `Notifications::SendReminder`) :
  une tâche peut avoir un rappel à une heure le jour de son échéance (les poubelles : 19 h). Une notification aux
  membres qui suivent le foyer, même avec le résumé coupé ; relancée toutes les heures, 3 au plus, rien après 22 h,
  pour une tâche à ne pas rater. Chaque envoi est réservé de façon atomique (jamais deux fois). « Fait » ou
  « Reporter » arrêtent les relances ; une échéance reportée est rappelée le lendemain ; changer la date remet les
  compteurs à zéro. La notification nomme la tâche (et sa plante), jamais son Comment faire, et ouvre sa feuille.
  L'app Android ne les reçoit pas encore (Firebase à venir).

## Moteur de récurrence

Ruby pur dans `app/domain/recurrence/`, sans ActiveRecord :

- `Recurrence::Once` : une seule échéance (`due_on`), aucune suivante après réalisation ;
- `Recurrence::Sliding` : `interval` jours (1 à 60), semaines (1 à 52), mois (1 à 24) ou ans (1 à 10) après la
  dernière réalisation (`unit`, `start_on` facultatif, date de la première échéance) ; un 31 tombe le dernier jour
  d'un mois plus court. Config `{ "interval", "unit", "start_on" }` (migration depuis `interval_days`, 23 novembre
  2026, l'ancien format n'est plus lu) ; `#interval_days` reste un lecteur pour l'arrosage, compté en jours ;
- `Recurrence::Fixed` : une ancre (`anchor_on`, « prochaine fois le ») et un pas de N semaines (1 à 52) ou N ans
  (1 à 10) ; le jour de la semaine ou la date de l'année se déduit de l'ancre (un 29 février tombe le 28 les autres
  années). Une ancre passée s'ouvre à sa prochaine date, qui devient l'ancre ; modifier « Prochaine fois le » déplace
  toute la série, modifier le reste (titre, Comment faire) ne touche ni l'ancre ni l'échéance ouverte (une poubelle
  reportée reste un mardi). Un « Fait » tapé sur une page affichée avant qu'un oubli ait ouvert la collecte suivante
  est refusé (« Trop tard »). Annuler un « Fait » rejoue la règle : la date reportée revient après un report ; une
  date passée revient et le job la note manquée comme tout oubli ;
- `Recurrence::OnDemand` : « quand il le faut », jamais d'échéance ouverte (jamais dans Aujourd'hui, jamais manquée
  ni rappelée) ; « Fait », sur la fiche de l'équipement ou de la plante, dans les tâches de la maison ou dans la
  feuille, enregistre directement une échéance faite (`Tasks::RecordDone`, une fois par jour), annulable depuis le
  journal ; la ligne montre la dernière fois. Le rythme se change en un rythme daté en modifiant la tâche.

Interface commune : `#next_due_at(last_completed_at:, last_due_on:, not_before:)`, `#period_days` (tolérance : un
quart de la période, de 0 à 3 jours) et `#dated?`, construits depuis `recurrence_type` + `recurrence_config` par
`Recurrence.build(type:, config:)` ; `nil` en retour signifie qu'il n'y a plus d'échéance. Le rythme d'une tâche se
change en la modifiant (`Tasks::Update`).

Après un oubli, la règle dépend du rythme et de l'importance (`Tolerance.after_miss`) :

| | à ne pas rater | souple |
|---|---|---|
| Une fois | terminée | jamais manquée |
| Après la dernière fois | rouverte (même échéance) | rouverte |
| À jour fixe | manquée, puis la date suivante de la règle (une collecte ne se rattrape pas) | manquée une fois, rouverte ; une fois faite, la suivante revient sur la règle |
| Quand il le faut | jamais manquée | jamais manquée |

L'usage (cycles, kilomètres) est hors v1 (`docs/conception/equipements-et-taches.md`).

## Catalogue des suggestions

Les types d'équipements (avec leur icône) et les tâches suggérées (de la maison, comme les poubelles, et par type
d'équipement : piscine, lave-vaisselle, chauffe-eau) sont décrits dans `config/catalogue.yml`, leurs textes dans `config/locales/catalogue.fr.yml` ; pas de
table (ADR 0016). Une suggestion est **copiée** dans la tâche à sa création (titre, rythme, importance, rappel,
Comment faire) : tout reste modifiable, y compris le type de rythme. Un équipement de type « Autre » n'a pas de
suggestion. Exemple complet et règles : `docs/conception/equipements-et-taches.md`.

- `Catalogue.suggestions_for(sujet)` : celles de la maison (sans sujet), celles du type d'un équipement, aucune pour
  une plante ; moins celles déjà ajoutées (`Task.used_suggestion_keys`, tâches actives).
- Après l'ajout d'un équipement dont le type a des suggestions, un écran « Ajouter des tâches d'entretien ? »
  (`Equipments::SuggestionsController`) les propose **décochées**, chacune avec son rythme et sa première date (une
  période après aujourd'hui, comme si elle venait d'être faite ; la prochaine date d'un rythme annuel) : rien
  n'arrive dans Aujourd'hui le jour de l'ajout. Les cochées sont ajoutées ensemble (`Tasks::AddSuggestions`, une
  transaction) ; « Plus tard » mène à la fiche. Les mêmes suggestions restent en puces dans « Ajouter une tâche » de
  la fiche.

## Équipements

- Maison → « Ajouter » → « Un équipement » : le type en pastilles (icône et nom du catalogue), le nom (celui du type
  si vide), et « À savoir » replié. La fiche (`equipment#show`) a deux onglets, Entretien (ses tâches avec leur
  rythme, « Ajouter une tâche », puis « À savoir », texte de l'utilisateur échappé) et Historique (le journal de ses
  tâches). Maison montre la section « Équipements » dès qu'il y en a un.
- Ses tâches se créent depuis sa fiche (`/equipment/:id/tasks/new`) et vivent comme les autres : Aujourd'hui les
  sous-titre du nom de l'équipement, avec l'icône de son type ; la feuille, le journal et les rappels le nomment.
- Un type retiré du catalogue se lit « Autre » : l'équipement reste affiché et modifiable.
- Pas d'archivage : supprimer un équipement (depuis sa modification, avec confirmation) supprime ses tâches et leur
  historique.
- Photos (`SubjectPhotosController`) : un onglet Photos sur la fiche de l'équipement (la plus récente lui sert de
  visage), et des photos dans la feuille d'une tâche, avec son Comment faire (le filtre à dévisser). Ajoutées en un
  geste, vues en grand, supprimées après confirmation ; pas de nouvelle photo pour une tâche arrêtée. Les photos d'une
  plante gardent leur visionneuse.

## Tâches de la maison

- Une tâche sans sujet appartient à la maison (poubelles, aérer la cave) : `Tasks::Add` la crée pour le foyer
  courant (`TasksController`, `/tasks/new`), elle se liste dans « Maison → Tâches de la maison » (une tâche unique déjà
  faite en sort, elle reste au journal) et apparaît dans « Aujourd'hui » sans sous-titre.
- Toute tâche a sa **feuille** (`tasks#show`, modale dans l'app) : le titre, la plante ou « Tâche de la maison », la
  prochaine échéance avec « Fait » et « Reporter », la dernière fois, et le **Comment faire** (texte de l'utilisateur,
  échappé, retours à la ligne gardés). Une ligne d'« Aujourd'hui » ou de la fiche plante ouvre la feuille (sauf
  l'arrosage, qui mène à la plante) ; une icône livre signale un Comment faire. La feuille mène à la modification ; la
  tâche se supprime depuis l'une ou l'autre, après confirmation (jamais l'arrosage).
- « Aujourd'hui » liste les tâches dès que le foyer suit quelque chose (une plante ou une tâche), même sans plante.

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
- Une tâche ne se fait qu'une fois par jour (`Tasks::Complete`) : un second « J'ai arrosé » le même jour est refusé.
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
