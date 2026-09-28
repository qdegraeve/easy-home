# Architecture

## Principes

1. **Lisible par un humain** : on doit comprendre ce que fait une action en lisant le contrôleur, puis le service.
2. **Testable unitairement** : chaque couche se teste seule, sans navigateur.
3. **Pas de surenchère** : une couche n'existe que si elle apporte quelque chose. Le MVC Rails reste la base ; les couches ci-dessous l'étendent sans le remplacer.

## Arborescence

```
app/
  controllers/     # minces : auth, authorize, appel, rendu
  models/          # ActiveRecord : associations, scopes simples, invariants
  forms/           # contrats : ActiveModel::Validations (+ SimpleDelegator)
  services/        # cas d'usage : Dry::Monads
    tasks/complete.rb           → Tasks::Complete
    items/add.rb                → Items::Add
  queries/         # query objects
    due_occurrences_query.rb    → DueOccurrencesQuery
  policies/        # Pundit
  components/      # ViewComponent (+ template .html.erb à côté)
  domain/          # Ruby pur, sans ActiveRecord
    recurrence/                 → Recurrence::Fixed, ::Sliding, ::UsageBased
  jobs/            # minces, délèguent à un service
  views/           # pages, partials spécifiques, turbo_stream
  javascript/controllers/       # Stimulus
config/
  task_templates/  # catalogue YAML des modèles de tâches
```

`app/domain` est chargé automatiquement par Zeitwerk (tout sous-dossier de `app/` l'est).

## Quand utiliser quoi

| Besoin | Où | À ne pas faire |
|---|---|---|
| CRUD simple sur un seul modèle | Contrôleur + modèle | Créer un service qui ne fait qu'un `create` |
| Action sur plusieurs modèles, ou avec effets de bord (push, job, API) | Service | Mettre l'effet de bord dans un callback de modèle |
| Validation dépendant du contexte ou multi-modèles | Formulaire | Ajouter des `if:` contextuels dans le modèle |
| Requête réutilisée ou complexe | Query object | Dupliquer la chaîne de `where` dans plusieurs fichiers |
| Requête simple et locale | Scope du modèle | Créer un query object pour un `where(active: true)` |
| Qui peut voir ou faire quoi | Policy | Filtrer à la main dans le contrôleur (`where(household: ...)`) |
| UI réutilisée ou avec logique d'affichage | ViewComponent | Mettre de la logique dans un partial ou un helper géant |
| Mise en page propre à une page, turbo_stream | Partial | Créer un composant utilisé une seule fois et sans logique |
| Calcul métier pur (récurrence) | `app/domain` | Dépendre d'ActiveRecord dans ce code |

## Contrôleurs

```ruby
class TaskOccurrences::CompletionsController < ApplicationController
  def create
    occurrence = policy_scope(TaskOccurrence).find(params[:task_occurrence_id])
    authorize occurrence, :complete?

    case Tasks::Complete.new.call(occurrence:, user: Current.user, params: completion_params)
    in Success(occurrence)
      redirect_to occurrence.task, notice: t(".success")
    in Failure[:invalid, form]
      render :new, locals: { form: }, status: :unprocessable_entity
    end
  end

  private

  def completion_params = params.fetch(:completion, {}).permit(:note, :indicator_on)
end
```

- Préférer des contrôleurs REST supplémentaires (`CompletionsController#create`) à des actions custom (`TasksController#complete`).
- Pas de logique métier dans le contrôleur.

## Services

```ruby
module Tasks
  class Complete
    include Dry::Monads[:result, :do]

    def call(occurrence:, user:, params: {})
      form = yield validate(occurrence, params)

      ActiveRecord::Base.transaction do
        yield mark_done(form, user)
        yield schedule_next(occurrence)
      end

      Success(occurrence)
    end

    private

    def validate(occurrence, params)
      form = Tasks::CompletionForm.new(occurrence, params)
      form.valid? ? Success(form) : Failure[:invalid, form]
    end

    def mark_done(form, user)
      form.save_completion!(by: user)
      Success()
    end

    def schedule_next(occurrence)
      Tasks::ScheduleNext.new.call(task: occurrence.task)
    end
  end
end
```

Conventions :

- Nom : `<Domaine>::<Verbe>` (`Tasks::Complete`, `Items::Add`, `Households::InviteGuest`).
- Une seule méthode publique `#call`, avec des arguments nommés.
- Retour : `Success(valeur)` ou `Failure[:code_symbolique, payload]`. Codes courants : `:invalid` (payload = formulaire), `:not_found`, `:forbidden`, `:external_error`.
- Avec la do notation, un `Failure` levé dans un bloc `transaction` provoque un rollback. C'est le comportement voulu.
- Un service peut en appeler un autre. Au-delà de deux niveaux d'imbrication, revoir le découpage.
- Les exceptions sont réservées à l'inattendu (bug, base indisponible). Un échec métier est un `Failure`.

## Formulaires (contrats)

**Formulaire qui enveloppe un enregistrement existant** :

```ruby
module Tasks
  class CompletionForm < SimpleDelegator
    include ActiveModel::Validations

    # Conserve les noms de paramètres et les routes de TaskOccurrence avec form_with
    def self.model_name = TaskOccurrence.model_name

    attr_reader :note, :indicator_on

    validates :note, length: { maximum: 500 }
    validate :must_be_pending

    def initialize(occurrence, params = {})
      super(occurrence)
      @note = params[:note]
      @indicator_on = ActiveModel::Type::Boolean.new.cast(params[:indicator_on])
    end

    def save_completion!(by:)
      __getobj__.update!(status: :done, completed_by: by, completed_at: Time.current,
                         note:, feedback: { indicator_on: })
    end

    private

    def must_be_pending
      errors.add(:base, :already_closed) unless pending?
    end
  end
end
```

**Formulaire de création qui ne correspond pas à un seul modèle** : `ActiveModel::Model` + `ActiveModel::Attributes`, sans `SimpleDelegator`.

Les validations d'**invariants** (non-nullité, unicité) restent dans le modèle. Le formulaire porte les règles propres à un **cas d'usage**.

## Query objects

```ruby
class DueOccurrencesQuery
  def initialize(relation = TaskOccurrence.all)
    @relation = relation
  end

  def call(at: Time.current)
    @relation.pending
             .joins(:task).merge(Task.active)
             .where(notify_at: ..at)
  end
end
```

- Nom : `<Quoi>Query`. Retourne toujours une relation, pour pouvoir la composer (`DueOccurrencesQuery.new(policy_scope(...)).call`).
- Pas de query sets ni de resource objects pour l'instant : à reconsidérer seulement si les query objects deviennent nombreux et redondants.

## Policies (Pundit)

- Chaque modèle exposé a sa policy. `ApplicationController` vérifie `verify_authorized` / `verify_policy_scoped` après chaque action.
- `Scope#resolve` borne toujours au foyer de l'utilisateur. Pour un `guest`, il borne en plus aux tâches ouvertes via `TaskAccess` (et à la période en cours).
- Les policies se testent unitairement, avec une matrice rôle × action.

## Composants (ViewComponent)

```ruby
class TaskCardComponent < ViewComponent::Base
  def initialize(occurrence:)
    @occurrence = occurrence
  end

  def overdue? = @occurrence.due_at.past?
end
```

- Nom : `<Quoi>Component`, avec le template `.html.erb` à côté.
- Pas d'accès à la base depuis un composant : on lui passe les données.
- Utiliser des previews (`spec/components/previews`) pour développer visuellement.

## Domaine pur

- `Recurrence::*` : objets valeur immuables, sans ActiveRecord ni `Time.now`. Le temps de référence est toujours passé en argument.
- C'est le code le plus critique de l'app : couverture de tests exhaustive (voir `docs/tests.md`).

## Jobs

```ruby
class SendDueRemindersJob < ApplicationJob
  def perform = Reminders::SendDue.new.call
end
```

Les jobs récurrents sont déclarés dans `config/recurring.yml`.

## Front (Hotwire)

- Turbo Drive, Frames et Streams d'abord. Stimulus seulement pour l'interactivité locale.
- Les pages doivent fonctionner dans la webview Hotwire Native (voir `docs/hotwire-native.md`) : pas d'interaction au survol uniquement, zones tactiles suffisantes.
- Tailwind 4 : classes utilitaires dans les templates. Extraire un composant plutôt que multiplier les `@apply`.
