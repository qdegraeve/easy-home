module Tasks
  # "Fait" on a task done when needed (Recurrence::OnDemand): it has no open occurrence, so the completion is recorded
  # directly as a done line of the journal, due the day it was done. Under the task lock, once a day, on an active task
  # only, like Tasks::Complete. Undone from the journal like any completion (Tasks::CancelCompletion).
  class RecordDone
    include Dry::Monads[:result, :do]

    def call(task:, user:)
      occurrence = ActiveRecord::Base.transaction do
        task.lock!
        yield ensure_recordable(task)

        completed_at = Time.current
        task.occurrences.create!(
          status: :done,
          due_at: completed_at.beginning_of_day,
          completed_at:,
          completed_by: user
        )
      end

      Success(occurrence)
    end

    private

    def ensure_recordable(task)
      return Failure[:not_on_demand, task] unless task.on_demand?
      return Failure[:inactive, task] unless task.active?
      return Failure[:already_done_today, task] if task.occurrences.done_on?(Time.zone.today)

      Success(task)
    end
  end
end
