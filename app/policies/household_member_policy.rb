# The members of a household (ADR 0019): everyone but a guest sees who is in it; a manager invites, renews a lost
# link, cancels an invitation, changes a role and removes someone; anyone leaves a household. The last manager is
# guarded by the services (Members::LastManager), which say why.
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

  # Renewing the link: a place still reserved only.
  def renew?
    create? && record.pending?
  end

  # The role of someone who joined.
  def update?
    create? && !record.pending?
  end

  def edit?
    update?
  end

  # Cancelling an invitation, removing someone, or leaving.
  def destroy?
    create? || own?
  end

  class Scope < ApplicationPolicy::Scope
    # The places of the households the user manages, and their own (to leave a household as a guest).
    def resolve
      return scope.none unless user

      scope.where(household_id: managed_household_ids).or(scope.where(user:))
    end
  end

  private

  def own?
    user.present? && record.user_id == user.id
  end

  def household_policy
    HouseholdPolicy.new(user, record.household)
  end
end
