# Équipements, tâches de la maison, nouvelles récurrences

> **Statut : validée par le propriétaire le 23 novembre 2026.** Réflexion menée par un agent produit et un agent
> architecte (deux allers-retours), puis arbitrée par le propriétaire. Décisions : ADR 0016 et 0017. Le schéma
> technique complet est en annexe ; `docs/domaine.md` décrit le modèle au fil des PR.

Principe qui a tout tranché : **un champ, un objet ou un écran n'existe que si l'app s'en sert ou si l'utilisateur va
le relire.**

## 1. Ce que l'utilisateur voit

| Mot | Ce que c'est | Exemples |
|---|---|---|
| **Équipement** | Un objet qu'on entretient : un nom, un type (liste courte + « Autre »), « À savoir » (texte libre), des photos. Facultatif. | Piscine, lave-vaisselle, chauffe-eau, clim, lave-linge, voiture |
| **Tâche** | Rattachée à un équipement, à une plante, ou à rien (« tâche de la maison »). | Nettoyer le filtre, sortir la poubelle jaune |
| **Comment faire** | Le mode opératoire, porté par **chaque tâche** (y compris sans équipement). Lu au moment de faire la tâche, dans sa feuille (appui sur la ligne d'Aujourd'hui ; le bouton « Fait » reste en un geste). | « Retirer le panier inférieur, dévisser le filtre… » |
| **À savoir** | Ce qu'on sait de l'équipement hors tâche. | Référence du filtre, garantie, réarmer la pompe |

- **Pas d'objet « consigne » séparé** ni de lien entre tâches et consignes : une indirection et un appui de moins ;
  deux tâches avec la même consigne sont rares.
- **La poubelle est une tâche de la maison, pas un équipement** : un objet « poubelle » n'apporterait rien qu'on
  relise. Plusieurs bacs = plusieurs tâches. Son échéance est **le jour où on la sort** (« Je la sors toutes les 2
  semaines, prochaine fois mar. 1er déc. »), le jour de collecte n'est pas stocké. « Rentrer la poubelle » est une
  suggestion séparée, souple.
- **Équipement générique, sans champs par type** (pas de volume de piscine, marque, garantie…) tant qu'aucune fonction
  ne s'en sert : la photo de la plaque et « À savoir » suffisent ; une fin de garantie à ne pas oublier devient une
  tâche « une fois ».

## 2. Les rythmes (sans mot technique à l'écran)

| Rythme | Exemple | Nouveau ? |
|---|---|---|
| Une fois | Fin de garantie | existe |
| Tous les N jours / semaines / mois / ans **après la dernière fois** | Anode tous les 2 ans, filtre tous les mois | unités nouvelles (aujourd'hui : jours) |
| **À jour fixe** : toutes les N semaines un jour donné, ou chaque année à une date | Poubelle un mardi sur deux, saison cyclonique le 1er nov. | nouveau |
| **Quand il le faut** : sans échéance, un bouton « Fait » et « dernière fois il y a 6 sem. » | Sel, liquide de rinçage (l'app ne voit pas le voyant) | nouveau |

- **Hors v1** : à l'usage (cycles, km) ; « le 2e mardi du mois ».
- **Un oubli suit l'importance** : une collecte « à ne pas rater » oubliée est notée manquée et la date suivante
  s'ouvre (elle ne se rattrape pas) ; une tâche souple oubliée est notée manquée une fois puis rouverte (sinon une
  tâche annuelle oubliée 3 jours disparaîtrait pour un an).
- Un seul champ **« Prochaine fois le »** dans le formulaire des tâches (remplace « dernière fois : aujourd'hui / je ne
  sais pas »).

## 3. Rappels à une heure

- Facultatif sur toute tâche datée, désactivé par défaut, **le jour de l'échéance** (de 5 h à 22 h, au quart d'heure).
- Tâche souple : une notification. Tâche « à ne pas rater » : relances toutes les heures, 3 au plus, rien après 22 h,
  chaque relance remplace la précédente. « Fait » ou « Reporter » arrêtent tout.
- Reçu par les membres qui suivent le foyer, même avec le résumé du matin coupé (« Foyers suivis : résumé du matin et
  rappels »). Le résumé du matin l'annonce : « Ce soir 19 h : sortir la poubelle jaune ».
- Texte : « Nettoyer le filtre · Lave-vaisselle », relance « Toujours à faire : … », jamais le Comment faire.
- Attention : l'app Android ne reçoit pas encore les notifications (pas de Firebase). Le serveur sera prêt ; il
  faudra la PR Android des notifications pour les voir sur le téléphone.

## 4. Parcours

- **Maison** gagne deux sections, masquées tant qu'elles sont vides : **Équipements** et **Tâches de la maison**. Le
  **+** de Maison propose : une plante, un équipement, une tâche.
- **Ajouter un équipement** (3 appuis au minimum) : type en grosses pastilles → nom pré-rempli, détails repliés →
  écran « Ajouter des tâches d'entretien ? » : les suggestions du type, **décochées**, chacune avec sa première date
  (« 1re fois le 23 déc. ») pour que rien n'envahisse Aujourd'hui le jour de l'ajout.
- **Fiche équipement** : le gabarit de la fiche plante, 3 onglets (Entretien avec « À savoir » dessous, Photos,
  Historique). Photo d'en-tête = la plus récente. Pas d'archivage en v1 : seulement Supprimer (la confirmation dit que
  l'historique part aussi).
- **Aujourd'hui** ne change pas de structure ; sous-titre d'une ligne = nom de l'équipement ou de la plante, sinon
  l'heure du rappel (« ce soir 19 h »), sinon rien. Jour férié : « Reporter » (deux fois si besoin).
- Suggestions v1 : Poubelles (maison), Piscine, Lave-vaisselle, Chauffe-eau, chacune avec son Comment faire.

## 5. Architecture

```
Household ─┬─< Plant ───────┬─< Photo (subject)
           │                └─< Task (subject) ─< TaskOccurrence
           ├─< Equipment ───┬─< Photo (subject)
           │                └─< Task (subject) ─< TaskOccurrence
           └─< Task (sans sujet : tâche de la maison) ─< TaskOccurrence
```

- **ADR 0016** (amende l'ADR 0010) : **un modèle par domaine qui calcule** (`Plant` aujourd'hui, `Pet` plus tard) et
  **un modèle générique `Equipment`** pour tout ce que l'app se contente de rappeler. Pas de jsonb « fourre-tout » :
  un champ propre à un type n'arrive qu'avec la fonction qui le lit (colonne ou table 1-1, par ADR à ce moment-là).
  Scalable : un nouvel objet à entretenir = une ligne de catalogue, pas une table.
- `Task#subject` reste polymorphe ; `Photo` le devient (migration en deux temps). Un « contrat de sujet » commun
  (nom, foyer, tâches, photos) vérifié par une spec partagée.
- `tasks` : `instructions` (Comment faire), `reminder_minute`, `suggestion_key` (d'où vient la tâche, sans effet) ;
  rythmes `once`, `sliding` (avec unités), `fixed`, `on_demand`.
- **Catalogue** des suggestions en YAML (`config/catalogue.yml`) + textes en I18n ; copiés dans la tâche à sa création
  (l'utilisateur peut tout modifier ensuite). Pas de table.
- **Moteur de récurrence** (Ruby pur, testé de façon exhaustive : fins de mois, 29 février, oublis, reports,
  annulations) : nouveau contrat commun ; la règle après un oubli croise rythme et importance.
- **Rappels** : un job toutes les 5 minutes qui trouve les rappels dus et les réserve de façon atomique (jamais de
  doublon). Écarté : un job planifié par échéance, à replanifier dans six services. **ADR 0017**.
- Un contrôleur de tâches unique pour plantes, équipements et maison ; `tasks#show` est la feuille de la tâche
  (modale dans l'app). La gem `ice_cube`, jamais utilisée, est retirée.

## 6. Livraison : 10 PR, chacune testée de bout en bout

| # | PR | Ce que tu obtiens |
|---|---|---|
| 0 | ADR 0016 et 0017, `domaine.md` réécrit | rien de visible |
| 1 | Tâches de la maison, Comment faire, feuille de la tâche | « Aérer la cave » avec sa façon de faire, lue et faite depuis Aujourd'hui |
| 2 | Jour fixe et suggestion poubelles | **la poubelle jaune un mardi sur deux, à ne pas rater** (promesse d'origine) |
| 3 | Rappels à une heure et relances (côté serveur) | « 19 h : sortir la poubelle jaune », relancé à 20 h et 21 h |
| 4 | Unités semaines / mois / ans | « Manœuvrer le groupe de sécurité tous les 3 mois » |
| 5 | Photos polymorphes (technique) | rien de visible |
| 6 | Équipements : fiche, À savoir, photos, tâches, photos d'une tâche | « Clim chambre » avec sa photo, ses notes, ses tâches ; le filtre en photo dans la feuille de sa tâche |
| 7 | « Quand il le faut » | « Remettre du sel » avec la dernière fois |
| 8 | Suggestions Piscine, Lave-vaisselle, Chauffe-eau | un lave-vaisselle et ses tâches d'entretien en 3 appuis |
| 9 | Nettoyage technique | rien |

Les PR 1 à 3 livrent la poubelle qui marche avant tout équipement.

## 7. Décisions du propriétaire (23 novembre 2026)

1. La poubelle est une tâche de la maison, pas un objet ; échéance le jour où on la sort.
2. « Comment faire » sur chaque tâche, « À savoir » sur l'équipement, sans objet consigne séparé. **Une liste de
   consignes d'un équipement est une liste de tâches** : une consigne qu'on veut seulement pouvoir relire, sans
   rappel, est une tâche « quand il le faut » (jamais dans Aujourd'hui, avec son Comment faire et sa dernière fois).
   **Une tâche peut avoir ses photos** (montrées dans sa feuille avec le Comment faire), en plus des photos de
   l'équipement : les photos polymorphes le permettent (`Photo#subject` = `Task`), livré avec les équipements.
3. Équipement générique (ADR 0016, amende l'ADR 0010). **Catalogue** : des types d'équipements avec leurs tâches
   préconstruites, enrichi par une PR (YAML + textes). **Équipement personnalisé** : le type « Autre », nom libre,
   sans suggestion, tâches créées à la main. Une tâche créée depuis le catalogue est une copie modifiable ; on ajoute
   ses propres tâches à tout équipement. Hors v1 : enregistrer sa propre tâche comme modèle réutilisable.
4. Rappel à une heure possible sur toute tâche ; relances réservées aux « à ne pas rater » (ADR 0017).
5. Le sel en « quand il le faut » par défaut ; l'usage (cycles, km) hors v1. **Chaque rythme est réglable** : le
   rythme d'une suggestion n'est qu'un défaut, le type de rythme se change en modifiant la tâche, historique gardé.
6. L'ajout d'une plante garde « Dernier arrosage ».
7. Ordre : PR 0 à 3 (la poubelle), puis les équipements.

## Annexe : schéma technique

### 1. Modèle de données final

#### 1.1 Principes (ADR 0016, amende l'ADR 0010)

- **Un modèle par domaine qui calcule** (`Plant` aujourd'hui, `Pet` plus tard), et **un modèle générique `Equipment`**
  pour tout ce que l'app se contente de rappeler (piscine, lave-vaisselle, chauffe-eau, clim, lave-linge, voiture,
  autre). Pas de jsonb `properties`. Un champ propre à un type n'arrive qu'avec la fonction qui le lit : colonne
  nullable validée selon le type, ou table 1-1 `<type>_details`, à décider par ADR à ce moment-là.
- `Task#subject` reste polymorphe (`Plant`, `Equipment`, nul pour une tâche de la maison). `Photo#subject` devient
  polymorphe de la même façon.
- **Contrat d'un sujet**, vérifié par une spec partagée (`it_behaves_like "a task subject"`) : `household_id` (en
  lecture seule), `name`, `archived?` (toujours faux pour un équipement), `tasks` et `photos` (`dependent: :destroy`),
  `face` (photo d'en-tête).
- Nom : `Equipment` est indénombrable dans Rails. Table `equipment`, helpers `equipment_index_path` /
  `equipment_path`, namespaces `Equipments::` (services, contrôleurs imbriqués).

#### 1.2 Tables

##### `equipment` (nouvelle)

| Colonne | Type | Contraintes |
|---|---|---|
| `id` | bigint | PK |
| `household_id` | bigint | not null, FK `households`, index ; `attr_readonly` |
| `kind` | string | not null ; validation `inclusion: Catalogue.equipment_kind_keys` (pas de CHECK : la liste suit le YAML) |
| `name` | string | not null ; ≤ 100 (validation) |
| `notes` | text | null ; ≤ 10 000 (validation) ; « À savoir » |
| `created_at`, `updated_at` | datetime | not null |

`Household has_many :equipment, dependent: :destroy`.

##### `tasks` (colonnes ajoutées)

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `instructions` | text | null ; ≤ 5 000 (validation) | « Comment faire » |
| `suggestion_key` | string | null | suggestion d'origine (`bins.yellow`) ; aucun comportement n'en dépend |
| `reminder_minute` | integer | null ; CHECK `reminder_minute BETWEEN 300 AND 1320` ; validation au quart d'heure | rappel le jour de l'échéance, en minutes après minuit, fuseau de l'application (sans heure d'été, ADR 0017) ; null = résumé du matin seulement |

- `recurrence_type` : `once`, `sliding`, `fixed`, `on_demand` (enum Rails, chaîne).
- `template_key` reste réservé aux tâches **gérées par leur sujet** (`plant.watering`). `Task#managed?` remplace
  `!manual?` dans `TaskPolicy`.
- Validation : `reminder_minute` nul pour `on_demand`.

##### `task_occurrences` (colonnes ajoutées)

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `reminders_sent` | integer | not null, défaut 0 | notifications de rappel envoyées pour cette échéance |
| `last_reminded_at` | datetime | null | dernier envoi |

Inchangés : `due_at not null`, l'index unique partiel « une seule `pending` par tâche », `reopened_after_miss`.

##### `photos` (rendue polymorphe)

| Colonne | Avant | Après |
|---|---|---|
| `plant_id` | not null, FK (nullable depuis la PR 5) | ignorée par le modèle, FK et index retirés (PR 9) ; colonne supprimée au déploiement suivant |
| `subject_type`, `subject_id` | — | string + bigint, nullables en base en PR 5 (déploiement sans coupure), requis par le modèle, not null en PR 9 ; index `[subject_type, subject_id, taken_at]` ; sujet : `Plant`, `Equipment` ou `Task` (photos d'une tâche, montrées dans sa feuille) |

Gardé : FK `plants.cover_photo_id → photos` (couverture des plantes seulement). Les validations remplacent la FK
perdue : `PlantAnalysisPhoto` vérifie que la photo est une photo de **cette** plante, `Plant` que sa couverture est
l'une de ses photos.

#### 1.3 Schéma

```
Household ─┬─< Plant ───────┬─< Photo (subject)
           │                └─< Task (subject) ─< TaskOccurrence
           ├─< Equipment ───┬─< Photo (subject)
           │                └─< Task (subject) ─< TaskOccurrence
           └─< Task (subject nul : tâche de la maison) ─< TaskOccurrence
```

### 2. Catalogue

#### 2.1 Fichiers

- `config/catalogue.yml` : structure (types, icônes, suggestions, récurrence, importance, rappel).
- `config/locales/catalogue.fr.yml` : tous les textes (noms des types, titres, Comment faire).
- `app/domain/catalogue.rb` (+ `Catalogue::Suggestion`, valeur immuable) : charge le YAML une fois, en Ruby pur.

#### 2.2 Exemple complet (poubelles, lave-vaisselle)

```yaml
# config/catalogue.yml
equipment_kinds:            # order of the type pills
  pool: { icon: waves, suggestions: [pool.ph, pool.skimmer, pool.backwash, pool.austral_winter, pool.cyclone_season] }
  dishwasher: { icon: utensils, suggestions: [dishwasher.filter, dishwasher.salt, dishwasher.rinse_aid] }
  water_heater: { icon: flame, suggestions: [water_heater.safety_valve, water_heater.anode] }
  air_conditioner: { icon: air_vent, suggestions: [] }
  washing_machine: { icon: washing_machine, suggestions: [] }
  car: { icon: car, suggestions: [] }
  other: { icon: wrench, suggestions: [] }

# Offered by the task form opened from Maison (no subject).
household_suggestions: [bins.yellow, bins.grey, bins.yellow_back, bins.bulky]

suggestions:
  bins.yellow:
    importance: critical
    reminder_minute: 1140                              # 19:00
    recurrence: { type: fixed, interval: 2, unit: weeks }
  bins.grey:
    importance: critical
    reminder_minute: 1140
    recurrence: { type: fixed, interval: 1, unit: weeks }
  bins.yellow_back:
    importance: flexible
    recurrence: { type: fixed, interval: 2, unit: weeks }
  bins.bulky:
    importance: flexible
    recurrence: { type: once }
  dishwasher.filter:
    importance: flexible
    recurrence: { type: sliding, interval: 1, unit: months }
  dishwasher.salt:
    importance: flexible
    recurrence: { type: on_demand }
  dishwasher.rinse_aid:
    importance: flexible
    recurrence: { type: on_demand }
  pool.cyclone_season:
    importance: flexible
    recurrence: { type: fixed, interval: 1, unit: years, month: 11, day: 1 }   # anchor = next Nov 1st
```

```yaml
# config/locales/catalogue.fr.yml
fr:
  catalogue:
    equipment_kinds:
      dishwasher: Lave-vaisselle
      # ...
    suggestions:
      bins:
        yellow:
          title: Sortir la poubelle jaune
          hint: La veille de la collecte.
        grey:
          title: Sortir la poubelle grise
          hint: La veille de la collecte.
        yellow_back:
          title: Rentrer la poubelle jaune
        bulky:
          title: Sortir les encombrants
      dishwasher:
        filter:
          title: Nettoyer le filtre
          instructions: |-
            Quart de tour pour le sortir.
            Rincer à l'eau chaude, brosse à dents.
        salt:
          title: Remettre du sel
          instructions: |-
            Bac au fond, entonnoir, jusqu'à débordement.
            Lancer un rinçage.
        rinse_aid:
          title: Remettre du liquide de rinçage
```

#### 2.3 Règles

- **Première échéance par défaut** (`Catalogue::Suggestion#first_due_on(today:)`) : `sliding` → aujourd'hui + une
  période ; `fixed` annuel → prochain `month`/`day` ≥ aujourd'hui ; `fixed` hebdo (poubelles) → aucune par défaut,
  l'utilisateur saisit « Prochaine fois le » (formulaire seulement, jamais à l'écran 2) ; `once` → aujourd'hui ;
  `on_demand` → aucune.
- `Catalogue.suggestions_for(subject_or_nil, existing_keys:)` : suggestions du type (ou de la maison), moins celles
  déjà ajoutées à ce sujet.
- Les textes sont **copiés** dans la tâche à la création ; changer le catalogue ne touche jamais aux tâches existantes.
- Spec du catalogue : chaque suggestion construit une `Recurrence` valide, a un titre I18n, chaque type a une icône
  connue d'`IconComponent` et ne référence que des suggestions existantes.

### 3. Moteur de récurrence

#### 3.1 Contrat (Ruby pur, `app/domain/recurrence/*`)

```ruby
# Recurrence.build(type:, config:) -> Once | Sliding | Fixed | OnDemand (raises Recurrence::InvalidConfig)
#
# #next_due_at(last_completed_at:, last_due_on:, not_before:)
#   The due date (TimeWithZone, start of the local day) of the occurrence to open after the last closed one, or nil
#   when there is none.
#   last_completed_at: last "done" (nil if never done)
#   last_due_on:       due date of the last done or missed occurrence (nil if none)
#   not_before:        earliest acceptable day (today minus the grace days); only Fixed uses it, to skip past dates
# #period_days -> approximate length of one period (Integer), nil for Once and OnDemand
# #dated?      -> false for OnDemand only (never an open occurrence)
```

| Règle | Config | `next_due_at` |
|---|---|---|
| `Once` | `{ due_on }` | `due_on` si jamais faite, sinon nil |
| `Sliding` | `{ interval, unit, start_on }` ; `unit` ∈ `days` (1..60), `weeks` (1..52), `months` (1..24), `years` (1..10) | jamais faite : `start_on` ; sinon dernière réalisation + période (`+ n`, `+ 7n`, `>> n`, `>> 12n`) |
| `Fixed` | `{ anchor_on, interval, unit }` ; `unit` ∈ `weeks` (1..52), `years` (1..10) | la première date `anchor_on + k·période` (k ≥ 0) **strictement après** `max(last_due_on, last_completed_on)` et **≥** `not_before` ; sans historique : la première ≥ `not_before` |
| `OnDemand` | `{}` | toujours nil |

- `period_days` : `n`, `7n`, `30n`, `365n` ; sert à la tolérance (un quart de la période, de 0 à 3 jours).
- `Fixed` : jour de la semaine et date de l'année déduits de l'ancre ; mois ramené en fin de mois (29 févr. → 28 févr.
  les années non bissextiles, via `Date#>>`). `Sliding#interval_days` reste un lecteur (unité jours) pour le code des
  plantes.
- Affichage (hors domaine, `RecurrenceLabel` en helper ou composant) : « toutes les 2 semaines, le mardi », « chaque
  année le 1er mai », « tous les 3 mois après la dernière fois », « quand il le faut ».

#### 3.2 Tolérance

`Tolerance.grace_days(importance:, recurrence:)` :

| | `critical` | `flexible` |
|---|---|---|
| `Once` | 0 | nil (jamais manquée) |
| `Sliding`, `Fixed` | 0 | `(period_days × 0.25).round.clamp(0, 3)` |
| `OnDemand` | nil | nil |

#### 3.3 Après un oubli

`Tolerance.after_miss(importance:, recurrence:)` → `:close`, `:reopen` ou `:advance` :

| | `critical` (à ne pas rater) | `flexible` (souple) |
|---|---|---|
| `Once` | `:close` (terminée, comme faite) | jamais manquée |
| `Sliding` | `:reopen` (même échéance, « prévu il y a 2 j ») | `:reopen` |
| `Fixed` | **`:advance`** : manquée au journal, puis la date suivante de la règle ≥ aujourd'hui (la collecte ne se rattrape pas) | **`:reopen`** : manquée au journal une fois, rouverte avec la même échéance, jamais manquée à nouveau ; une fois faite, la suivante revient sur la règle (strictement après la dernière échéance) |
| `OnDemand` | jamais manquée | jamais manquée |

`Recurrence#closed_by_miss?` disparaît.

Exemples (poubelle jaune un mardi sur deux, ancre mar. 1er déc.) :

- faite lun. 30 nov. ou mar. 1er → suivante mar. 15 ;
- reportée mar. 1er → ouverte mer. 2 ; faite mer. 2 → suivante mar. 15 ;
- oubliée → manquée mer. 2 au journal, ouverte mar. 15.

Saison cyclonique (souple, annuelle, 1er nov.) : oubliée → manquée le 5 nov. (3 jours de tolérance), rouverte « prévu
il y a 4 j » ; faite le 10 → suivante le 1er nov. de l'année suivante.

#### 3.4 Services du moteur

| Service | Comportement |
|---|---|
| `Tasks::Complete` | `next_due_at(last_completed_at: now, last_due_on: occurrence.due_at.to_date, not_before: today - grace)`. Une tâche `on_demand` n'a jamais d'échéance ouverte : elle passe par `RecordDone`. |
| `Tasks::MarkMissed` | `case Tolerance.after_miss` : `:reopen` → même échéance, `reopened_after_miss: true` ; `:advance` → `next_due_at(last_due_on: missed.due_at, not_before: today)` ; `:close` → rien. |
| `Tasks::Reschedule` | rejoue la règle depuis la dernière échéance close (`done` ou `missed`) : si c'est une `missed` et que `after_miss` vaut `:reopen` → rouverte à sa date (`reopened_after_miss: true`) ; si `:close` → aucune ; sinon `next_due_at`. Puis la règle existante « jamais avant le lendemain d'un report postérieur ». `Tolerance.earliest` n'est appliquée qu'aux règles **non fixes** (pour `Fixed`, `not_before` saute aux dates de la règle). |
| `Tasks::Postpone`, `CancelPostponement`, `CancelCompletion` | inchangés (`CancelCompletion` appelle `Reschedule`). |
| `Tasks::RecordDone(task:, user:)` | nouveau, `on_demand` seulement : sous `task.lock!`, crée une échéance `done` avec `due_at = completed_at.beginning_of_day` ; une fois par jour, tâche active. |

Specs exhaustives : chaque règle × importance × (faite à l'avance, à l'heure, en retard, reportée, oubliée, annulée),
fins de mois, 29 février, changement d'année, ancre passée.

### 4. Rappels à une heure

#### 4.1 Règles

- Rappel facultatif sur toute tâche datée (`reminder_minute`), désactivé par défaut, **le jour de l'échéance**.
- Une tâche souple : **une** notification. Une tâche à ne pas rater : relances, **3 notifications au plus**, au moins
  **une heure** d'écart, **aucune après 22 h**.
- Destinataires : membres non invités qui suivent le foyer (`HouseholdMember#digest`), **même si leur résumé est
  désactivé** (`User#digest_enabled` ignoré), sur chacun de leurs téléphones.
- Pas de rappel pour une échéance rouverte après un oubli (son jour est passé) ; une échéance reportée au lendemain
  est rappelée le lendemain, à la même heure.

#### 4.2 Mécanisme

- `SendRemindersJob`, récurrent **toutes les 5 minutes** (`config/recurring.yml`), appelle
  `Notifications::SendReminders`.
- `RemindersDueQuery.new.call(now:)` : échéances `pending`, `reopened_after_miss = false`, de tâches actives avec
  `reminder_minute`, dont le **jour d'échéance est aujourd'hui** dans le fuseau de l'application et où, en SQL :
  - `now >= due_at + reminder_minute minutes + reminders_sent heures` (k-ième envoi à l'heure + k h) ;
  - `now < due_at + 22 h` ;
  - `reminders_sent = 0`, ou `reminders_sent < 3`, tâche `critical` et `last_reminded_at <= now - 55 min` (marge pour le
    passage toutes les 5 minutes : 19 h 00 puis 20 h 00 ou 20 h 05, pas 20 h 10).
- `Notifications::SendReminder(occurrence:)` : réservation atomique
  (`UPDATE task_occurrences SET reminders_sent = reminders_sent + 1, last_reminded_at = now WHERE id = ? AND
  reminders_sent = <valeur lue>`), puis `deliver_later_to` les téléphones des destinataires. Jamais deux envois pour le
  même passage, même si deux jobs se chevauchent.
- Notification :
  - titre : « Sortir la poubelle jaune » ou « Nettoyer le filtre · Lave-vaisselle » ; relance : « Toujours à faire :
    sortir la poubelle jaune » ;
  - jamais le Comment faire ;
  - `thread_id: "task-#{task.id}"` (la relance remplace la précédente), `data: { path: task_path(task) }`.
- « Fait » ou « Reporter » arrêtent les relances (l'échéance n'est plus `pending`).

Écartés : un job planifié par échéance (à replanifier dans six services, Solid Queue n'annule pas proprement) et une
colonne `remind_at` (donnée dérivée à tenir à jour partout). ADR 0017 « Rappels à heure fixe ».

#### 4.3 Résumé du matin

`Notifications::SendDigest#label` : une tâche avec un rappel est préfixée par son heure (« Ce soir 19 h : sortir la
poubelle jaune »). `DueOccurrencesQuery` est inchangée. Libellé de réglage renommé « Foyers suivis : résumé du matin et
rappels ».

### 5. Formulaires, services, query objects, policies

#### 5.1 `TaskForm` (un seul formulaire pour toutes les tâches)

| Attribut | Pour | Validation |
|---|---|---|
| `title` | tous | présent, ≤ 100 |
| `recurrence_type` | tous | `once`, `sliding`, `fixed`, `on_demand` (**modifiable**) |
| `due_on` (« Prochaine fois le ») | tous sauf `on_demand` | présent ; pour `fixed`, c'est l'ancre |
| `interval`, `unit` | `sliding`, `fixed` | bornes par unité ; `fixed` : `weeks` ou `years` |
| `critical` | tous sauf `on_demand` | booléen |
| `reminder_minute` | tous sauf `on_demand` | nul ou dans `User::DIGEST_MINUTES` |
| `instructions` | tous | ≤ 5 000 |
| `suggestion_key` | création | clé du catalogue, sinon ignorée |

Pré-remplissage : `sliding` → aujourd'hui + une période ; suggestion → `first_due_on` ; `once` → aujourd'hui.

`Tasks::Update`, modification de la récurrence :

- même type : l'échéance ouverte passe à `due_on` (comme aujourd'hui) ; pour `fixed`, l'ancre devient `due_on` (toute
  la série se décale) ;
- vers `on_demand` : l'échéance ouverte est supprimée ;
- depuis `on_demand` : une échéance est ouverte à `due_on` ;
- `reopened_after_miss` remis à faux (nouvelle échéance), `reminders_sent` remis à 0 si la date change.

#### 5.2 Services

| Service | Rôle |
|---|---|
| `Tasks::Add(household:, subject:, params:)` | `subject` nul possible ; première échéance sauf `on_demand` ; `suggestion_key`. |
| `Tasks::AddSuggestions(subject:, keys:)` | écran 2 : crée les suggestions cochées avec leur `first_due_on`, en une transaction. |
| `Tasks::Update` | § 5.1. |
| `Tasks::Complete`, `MarkMissed`, `Reschedule` | § 3.4. |
| `Tasks::RecordDone` | § 3.4. |
| `Equipments::Add(household:, params:, file:)` | crée l'équipement et sa première photo facultative (`Photos::Add`), en une transaction. |
| `Photos::Add(subject:, file:)` | généralisé (`plant:` → `subject:`) ; refus si `subject.archived?`. |
| `Notifications::SendReminders` / `SendReminder` | § 4.2. |

CRUD simples dans les contrôleurs : modifier un équipement (`update`), supprimer un équipement (`destroy!`, cascade sur
les tâches, leurs échéances et les photos), supprimer une tâche.

#### 5.3 Query objects et scopes

- `DueOccurrencesQuery` : inchangée.
- `RemindersDueQuery` : nouvelle.
- `SubjectHistoryQuery.new(scope).call(subject:)` : échéances closes des tâches d'un sujet (onglet Historique de la
  plante et de l'équipement).
- Scopes : `Task.without_subject`, `Task.to_do` (active avec une échéance ouverte).

#### 5.4 Policies

- `HouseholdRecordPolicy` (nouvelle classe parente) : `manage?` = `HouseholdPolicy#update?` ; `Scope` par
  `managed_household_ids`. `PlantPolicy` et `EquipmentPolicy` en héritent.
- `EquipmentPolicy` : `show? create? new? update? edit? destroy?` = `manage?`.
- `TaskPolicy` : ajoute `show?` (la feuille) et `record_done?` (`manage?` : une page périmée, tâche datée ou arrêtée depuis, reçoit le message du service) ;
  `update?`/`destroy?` sur `!record.managed?`.
- `PhotoPolicy` : délègue au sujet : voir une photo = voir le sujet (`show?`) ; ajouter, changer la date = modifier le
  sujet (`update?`), refusé si le sujet est archivé pour l'ajout ; supprimer = pouvoir supprimer le sujet
  (`destroy?` : les photos d'une plante archivée ou de ses tâches restent supprimables). Pas de `Scope` : une photo est
  toujours cherchée parmi celles de son sujet, lui-même trouvé par `policy_scope`.
- `TaskOccurrencePolicy` : inchangée.

### 6. Routes, contrôleurs, vues

```ruby
get "house", to: "house#show", as: :house
get "house/new", to: "house#new", as: :new_house_item           # « Que voulez-vous ajouter ? »
get "house/tasks", to: "house_tasks#index", as: :house_tasks    # tâches de la maison

resources :plants do
  # archive, analyses: unchanged
  resources :tasks, only: [ :new, :create ], controller: "/tasks"
  resources :photos, only: [ :create, :show, :edit, :update, :destroy ], module: :plants do   # inchangées
    resource :cover, only: :create, controller: "/plants/covers"
  end
end

resources :equipment, except: :index do
  resource :suggestions, only: [ :new, :create ], module: :equipments   # écran 2
  resources :tasks, only: [ :new, :create ], controller: "/tasks"
  resources :photos, only: [ :create, :show, :destroy ], controller: "subject_photos"
end
get "equipment", to: "equipment#index", as: :equipment_index   # Maison → Équipements

resources :tasks, only: [ :new, :create, :show, :edit, :update, :destroy ] do   # new/create without subject = maison
  resource :completion, only: :create, module: :tasks                         # « Fait » d'une tâche on_demand
end
```

| Contrôleur | Rôle |
|---|---|
| `TasksController` | sujet trouvé par `plant_id` ou `equipment_id` via `policy_scope` (`SUBJECTS = { plant_id: Plant, equipment_id: Equipment }`), aucun pour la maison ; `show` = feuille (titre, sujet, Comment faire, dernière fois, Fait / Reporter) ; `new?suggestion=…` pré-remplit. Remplace `Plants::TasksController`. |
| `Tasks::CompletionsController#create` | `Tasks::RecordDone`. |
| `SubjectPhotosController` (fait, PR 6b) | photos d'un équipement et d'une tâche (`/equipment/:id/photos`, `/tasks/:id/photos`) : ajouter, voir en grand, supprimer ; sujet par l'URL via `policy_scope`. Les photos de plante gardent `Plants::PhotosController` et sa visionneuse. **Reporté** : corriger la date d'une photo d'équipement ou de tâche (ADR 0011), le défilement entre photos. |
| `EquipmentController` | `index`, `show` (`?tab=care|photos|history`), `new` (écran 1 : `?kind=` choisit le type), `create` (→ écran 2 si le type a des suggestions), `edit`, `update` (type compris), `destroy`. |
| `Equipments::SuggestionsController` | `new` (cases décochées, rythme et « 1re fois le … » par ligne), `create` (`Tasks::AddSuggestions`). |
| `HouseController` | `show` : sections Plantes, Équipements, Tâches de la maison, Lieux (vides masquées) ; `new` : trois choix. |
| `HouseTasksController#index` | tâches actives sans sujet. |

Vues et composants :

- Extraits de la fiche plante : `SubjectHeaderComponent` (photo la plus récente ou icône du type, nom, sous-titre),
  `SubjectTabsComponent` (3 onglets avec compteurs), `PhotoGridComponent(subject:)`, onglet Historique via
  `SubjectHistoryQuery` + `JournalEntryComponent`.
- Onglet Entretien d'un équipement : tâches datées (« dans 12 j › ») et `on_demand` (« il y a 6 sem. [Fait] »), « +
  Ajouter une tâche », puis le bloc À savoir (`simple_format`, ou le lien « Ajouter des notes » s'il est vide).
- `TaskRowComponent` : lien vers `task_path` (sauf arrosage) ; icône livre si `instructions` est rempli ; sous-titre
  optionnel.
- `TaskListComponent#row_detail` : « Arrosage » pour un arrosage ; sinon le nom du sujet ; sinon l'heure du rappel ;
  sinon rien. Icône de domaine : type d'équipement (catalogue), maison pour une tâche sans sujet.
- Android (`config/hotwire/android_v1.json` et sa copie embarquée) : `/tasks/\d+$` → modale ;
  `/(equipment|tasks)/\d+/photos/\d+$` → comme les photos de plante (sans pull-to-refresh). Une photo ouverte depuis
  la feuille d'une tâche (modale) s'empile sur l'écran principal ; supprimée, l'app revient à la feuille.

### 7. Migrations (dans l'ordre des PR, toutes compatibles avec les données existantes)

| PR | Migration | Données |
|---|---|---|
| 1 | `AddInstructionsToTasks` : `instructions text` | — |
| 2 | `AddSuggestionKeyToTasks` : `suggestion_key string` | — |
| 3 | `AddReminderMinuteToTasks` : `reminder_minute integer` + CHECK 300..1320 ; `AddRemindersToTaskOccurrences` : `reminders_sent integer default 0 not null`, `last_reminded_at datetime` | — |
| 4 | `MoveSlidingIntervalToUnit` | **transformation** : `UPDATE tasks SET recurrence_config = (recurrence_config - 'interval_days') \|\| jsonb_build_object('interval', recurrence_config->'interval_days', 'unit', 'days') WHERE recurrence_type = 'sliding' AND recurrence_config ? 'interval_days'` ; `down` inverse (unité jours seulement, refus s'il existe une autre unité). Spec de la migration. |
| 5 | `AddSubjectToPhotos` | **transformation** : ajout `subject_type`/`subject_id` nullables, `UPDATE photos SET subject_type = 'Plant', subject_id = plant_id`, index, `plant_id` rendu nullable (encore écrit pour une plante). Spec. |
| 6 | `CreateEquipment` | — |
| 9 | `RequireSubjectOfPhotos` et `ConvertLeftoverIntervalDays`, une fois les PR 1 à 8 en production | **transformation** : rattraper les photos ajoutées par l'ancien code pendant le déploiement (`UPDATE photos SET subject_type = 'Plant', subject_id = plant_id WHERE subject_id IS NULL AND plant_id IS NOT NULL`), `not null` sur le sujet, suppression de la FK et de l'index de `plant_id` (colonne ignorée par le modèle, supprimée au déploiement suivant) ; reconvertir les tâches glissantes restées en `interval_days`, dont l'ancien format n'est plus lu. Specs. |

Pas de `db:rollback` à l'aveugle (base de dev réelle) : `db:migrate:down VERSION=…` pour vérifier chaque `down`.

### 8. Découpage en PR (dans l'ordre)

Chaque PR met à jour `docs/domaine.md`, `docs/tests.md` (parcours critiques) et l'ADR concernée.

| # | PR | Ce que l'utilisateur obtient | System specs (parcours de bout en bout) |
|---|---|---|---|
| 0 | ADR 0016 (domaines, équipement générique, photos polymorphes, retrait d'`ice_cube`) et ADR 0017 (rappels à heure fixe) ; `domaine.md` nettoyé (retrait d'`UsageBased`, `notify_at`, `skipped`, etc.) | rien de visible | — |
| 1 | **Tâches de la maison** : `TasksController` unique, tâche sans sujet, Comment faire, feuille de la tâche (modale Android), section « Tâches de la maison », `+` de Maison (Plante / Tâche), sous-titre d'Aujourd'hui | une tâche « Aérer la cave » avec sa façon de faire, lue et faite depuis Aujourd'hui | créer une tâche de la maison avec Comment faire → Aujourd'hui (icône livre, pas de sous-titre) → feuille → Fait → journal ; les specs des tâches de plante restent vertes |
| 2 | **Jour fixe et poubelles** : `Recurrence::Fixed`, nouveau contrat du moteur, `Tolerance.after_miss`, services adaptés, « Prochaine fois le » partout, suggestions de la maison (poubelles), `suggestion_key`, retrait d'`ice_cube` | la poubelle jaune un mardi sur deux, à ne pas rater | ajouter « Sortir la poubelle jaune » depuis la suggestion → affichée « toutes les 2 semaines, le mardi » → Fait le mardi → suivante dans 2 semaines ; oubliée (`travel_to`) → manquée au journal, la suivante ouverte ; une tâche annuelle souple oubliée est rouverte |
| 3 | **Rappels à une heure** : `reminder_minute`, relances, `SendRemindersJob`, champ Rappel, préfixe d'heure dans le résumé et la ligne, libellé « Foyers suivis » | « 19 h : sortir la poubelle jaune », relancé à 20 h et 21 h | régler un rappel à 19 h → sous-titre « ce soir 19 h » ; specs de service avec `travel_to` : 1re notification à 19 h, relances, rien après 22 h, rien après Fait, une seule pour une tâche souple, pas de doublon, retard rattrapé sans rafale, destinataires (`digest` du membre, résumé désactivé), `path` vers la feuille |
| 4 | **Unités de « après la dernière fois »** : `Sliding` en jours / semaines / mois / ans, migration de données | « Manœuvrer le groupe de sécurité tous les 3 mois » | créer « tous les 3 mois » → Fait → « dans 3 mois » ; arrosage inchangé ; spec de la migration |
| 5 | **Photos polymorphes** (refactorisation) | rien de visible | specs photos et analyses des plantes inchangées et vertes ; spec de la migration |
| 6 | **Équipements** : modèle, écran 1 (types en pastilles), fiche à 3 onglets, À savoir, photos, tâches depuis la fiche, section Équipements, `+` à trois choix, photos d'une tâche (dans sa feuille), modifier (type compris), supprimer | « Clim chambre » avec sa photo, ses notes et ses tâches | ajouter un équipement avec photo et À savoir → fiche → ajouter une tâche → la faire depuis Aujourd'hui (sous-titre = nom) → supprimer (confirmation) → tâches et journal partis ; spec partagée « a task subject » |
| 7 | **« Quand il le faut »** : `OnDemand`, `Tasks::RecordDone`, « il y a 6 sem. [Fait] » sur la fiche, passage d'un rythme à l'autre | « Remettre du sel » sans rappel, avec la dernière fois | tâche « quand il le faut » sur un équipement → absente d'Aujourd'hui → Fait sur la fiche → « aujourd'hui », au journal, annulable ; la passer à « tous les mois » → échéance ouverte |
| 8 | **Suggestions par type** : Piscine, Lave-vaisselle, Chauffe-eau avec leur Comment faire ; écran 2 ; suggestions dans le formulaire d'une fiche | ajouter un lave-vaisselle et ses 3 tâches d'entretien en 3 appuis | ajouter un lave-vaisselle → écran 2 (« 1re fois le … » sur chaque ligne) → cocher le filtre et le sel → fiche avec les deux tâches et leur Comment faire ; rien dans Aujourd'hui ; spec de cohérence du catalogue |
| 9 | **Nettoyage**, déployé après les PR 1 à 8 : sujet des photos requis en base, `photos.plant_id` ignorée (supprimée au déploiement suivant), ancien format `interval_days` plus lu | rien | specs vertes |