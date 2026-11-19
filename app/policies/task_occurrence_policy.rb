class TaskOccurrencePolicy < ApplicationPolicy
  def complete?
    HouseholdPolicy.new(user, record.task.household).update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      households = user.household_members.where.not(role: :guest).select(:household_id)
      scope.joins(:task).where(tasks: { household_id: households })
    end
  end
end
