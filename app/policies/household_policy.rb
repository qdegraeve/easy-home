class HouseholdPolicy < ApplicationPolicy
  def show?
    user.present? && record.is_a?(Household) && record.users.include?(user)
  end

  def create?
    user.present?
  end

  def new?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      scope.where(id: user.household_members.select(:household_id))
    end
  end
end
