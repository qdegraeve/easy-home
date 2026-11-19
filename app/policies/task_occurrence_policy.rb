class TaskOccurrencePolicy < ApplicationPolicy
  def complete?
    HouseholdPolicy.new(user, record.task.household).update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      scope.joins(:task).where(tasks: { household_id: managed_household_ids })
    end
  end
end
