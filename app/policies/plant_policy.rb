# Owner and member manage plants. A guest has no access (their opened tasks will come with TaskAccess).
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
