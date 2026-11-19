class HouseholdPolicy < ApplicationPolicy
  def show?
    member.present?
  end

  # Propriétaire et membre gèrent la maison ; un invité ne la voit que pour ses tâches.
  def update?
    member.present? && !member.guest?
  end

  def edit?
    update?
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
