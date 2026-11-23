# Owner and member manage the equipment of their households, like the plants. A guest has no access.
class EquipmentPolicy < ApplicationPolicy
  def show?
    manage?
  end

  def create?
    manage?
  end

  def new?
    manage?
  end

  def update?
    manage?
  end

  def edit?
    manage?
  end

  def destroy?
    manage?
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
end
