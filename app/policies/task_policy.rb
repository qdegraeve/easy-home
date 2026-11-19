# Tâches d'un foyer : propriétaire et membre les gèrent. Seules les tâches manuelles se modifient et se suppriment
# ici ; une tâche créée avec son sujet (arrosage) se règle depuis le sujet. Un sujet archivé ne reçoit ni nouvelle
# tâche ni modification (il faut le restaurer) ; ses tâches restent supprimables.
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
