# What belongs to a household and is managed like it (a plant, an equipment): its managers and members see and
# change it; a guest has no access (their opened subjects will come with GuestAccess, ADR 0019). The records of the
# managed households only.
class HouseholdRecordPolicy < ApplicationPolicy
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
    HouseholdPolicy.new(user, record.household).manage?
  end
end
