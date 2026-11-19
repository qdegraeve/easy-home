# Propriétaire et membre gèrent les plantes. Un invité n'y a pas accès (ses tâches ouvertes viendront avec TaskAccess).
class PlantPolicy < ApplicationPolicy
  def show? = manage?
  def create? = manage?
  def new? = manage?
  def update? = manage?
  def edit? = manage?
  def destroy? = manage?
  def archive? = manage?
  def restore? = manage?

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
