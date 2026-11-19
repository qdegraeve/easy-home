class HouseholdPolicy < ApplicationPolicy
  def show?
    user.present? && record.is_a?(Household) && record.users.include?(user)
  end
end
