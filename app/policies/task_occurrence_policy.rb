# Doing, postponing or undoing an occurrence: whoever may do its task (managers, members, and a guest for a task
# opened to them, ADR 0019).
class TaskOccurrencePolicy < ApplicationPolicy
  def complete?
    TaskPolicy.new(user, record.task).record_done?
  end

  def postpone?
    complete?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      scope.joins(:task).merge(TaskPolicy::Scope.new(user, Task).resolve)
    end
  end
end
