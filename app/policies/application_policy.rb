class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    private

    attr_reader :user, :scope

    # Households where the user manages plants and tasks: owner or member, not guest.
    def managed_household_ids
      user.household_members.where.not(role: :guest).select(:household_id)
    end
  end
end
