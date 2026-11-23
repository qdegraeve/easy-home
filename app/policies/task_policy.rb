# Tasks of a household: owner and member manage them. Only manual tasks are edited and deleted here; a task created
# with its subject (watering) is set up from the subject. An archived subject gets neither new tasks nor edits (it
# must be restored first); its tasks can still be deleted.
class TaskPolicy < ApplicationPolicy
  # The task sheet: what to do and how.
  def show?
    manage?
  end

  # "Fait" on a task done when needed: the service says why it cannot be (a stale page: dated or stopped since).
  def record_done?
    manage?
  end

  def create?
    manage? && !subject_archived?
  end

  def new?
    create?
  end

  def update?
    manage? && record.manual? && !subject_archived?
  end

  def edit?
    update?
  end

  def destroy?
    manage? && record.manual?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      scope.where(household_id: managed_household_ids)
    end
  end

  private

  def manage?
    HouseholdPolicy.new(user, record.household).update?
  end

  def subject_archived?
    record.subject.respond_to?(:archived?) && record.subject.archived?
  end
end
