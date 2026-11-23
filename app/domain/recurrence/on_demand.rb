module Recurrence
  # "Quand il le faut": no due date, ever (the salt of the dishwasher: the app cannot see its light). Done when needed,
  # from the task itself (Tasks::RecordDone), with the last time shown; never in "Aujourd'hui", never missed, never
  # reminded. The rhythm can be changed into a dated one when editing the task.
  class OnDemand
    def next_due_at(last_completed_at:, last_due_on: nil, not_before: nil) # rubocop:disable Lint/UnusedMethodArgument
      nil
    end

    def period_days
      nil
    end

    def dated?
      false
    end
  end
end
