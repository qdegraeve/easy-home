class HouseholdPolicy < ApplicationPolicy
  def show?
    user.present? && record.users.include?(user)
  end
end
