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

    # Foyers où l'utilisateur gère les plantes et les tâches : propriétaire ou membre, pas invité.
    def managed_household_ids
      user.household_members.where.not(role: :guest).select(:household_id)
    end
  end
end
