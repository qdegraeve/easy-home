# Roles (ADR 0019): managers and members manage what the house holds (plants, equipment, tasks, places); only managers
# change the household itself (its address) and, later, its members. A guest only sees it for their tasks.
class HouseholdPolicy < ApplicationPolicy
  def show?
    member.present?
  end

  # Plants, equipment, tasks and places of the house.
  def manage?
    member.present? && !member.guest?
  end

  # "Ma maison": its places are managed by every member; its address is shown to them, changed by a manager.
  def edit?
    manage?
  end

  def update?
    member.present? && member.manager?
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

  private

  def member
    return unless user && record.is_a?(Household)

    @member ||= record.members.find_by(user:)
  end
end
