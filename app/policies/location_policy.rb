class LocationPolicy < ApplicationPolicy
  def create?
    HouseholdPolicy.new(user, record.household).update?
  end

  def update?
    create?
  end

  def edit?
    update?
  end

  def destroy?
    create?
  end
end
