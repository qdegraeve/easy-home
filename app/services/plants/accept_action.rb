module Plants
  # Turns an action proposed by an AI analysis into a one-off task of the plant (ADR 0008), at most once per action.
  # It is due the proposed number of days after the analysis, and never in the past.
  class AcceptAction
    include Dry::Monads[:result, :do]

    def call(analysis:, index:)
      ActiveRecord::Base.transaction do
        analysis.lock!
        action = yield find_action(analysis, index)
        task = yield add_task(analysis, action)
        analysis.update!(applied_action_indexes: analysis.applied_action_indexes + [ index ])
        Success(task)
      end
    end

    private

    def find_action(analysis, index)
      action = analysis.actions[index] if analysis.done? && index.between?(0, analysis.actions.size - 1)
      return Failure[:not_acceptable, analysis] unless action
      return Failure[:already_accepted, analysis] if analysis.action_accepted?(index)

      Success(action)
    end

    def add_task(analysis, action)
      due_on = [ analysis.finished_at.to_date + action["due_in_days"], Time.zone.today ].max
      Tasks::Add.new.call(
        subject: analysis.plant,
        params: { title: action["title"], recurrence_type: "once", due_on: }
      )
    end
  end
end
