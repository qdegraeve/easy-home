# Tâches d'un foyer : propriétaire et membre les gèrent. Seules les tâches manuelles se modifient et se suppriment ici ;
# une tâche créée avec son sujet (arrosage) se règle depuis le sujet.
class TaskPolicy < ApplicationPolicy
  def create? = manage?
  def new? = create?
  def update? = manage? && record.manual?
  def edit? = update?
  def destroy? = update?

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
end
