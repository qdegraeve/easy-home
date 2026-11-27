# The members of a household (ADR 0019): everyone but a guest sees who is in it; a manager invites, renews a lost
# link and cancels an invitation not accepted yet.
class HouseholdMemberPolicy < ApplicationPolicy
  def index?
    household_policy.manage?
  end

  def create?
    household_policy.update?
  end

  def new?
    create?
  end

  # Renewing the link and cancelling: a place still reserved only.
  def renew?
    create? && record.pending?
  end

  def destroy?
    renew?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      scope.where(household_id: managed_household_ids)
    end
  end

  private

  def household_policy
    HouseholdPolicy.new(user, record.household)
  end
end
