# Tasks of a household: owner and member manage them. Only manual tasks are edited and deleted here; a task created
# with its subject (watering) is set up from the subject. An archived subject gets neither new tasks nor edits (it
# must be restored first); its tasks can still be deleted.
class TaskPolicy < ApplicationPolicy
  def create? = manage? && !subject_archived?
  def new? = create?
  def update? = manage? && record.manual? && !subject_archived?
  def edit? = update?
  def destroy? = manage? && record.manual?

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
