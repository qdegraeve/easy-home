module TaskOccurrences
  class CompletionsController < ApplicationController
    def create
      occurrence = find_occurrence
      result = Tasks::Complete.new.call(occurrence:, user: Current.user)

      notice = if result.success?
        t(".success", title: occurrence.task.title, subject: occurrence.task.subject&.name)
      else
        t(".#{result.failure.first}")
      end
      redirect_back_or_to root_path, notice:, status: :see_other
    end

    def destroy
      occurrence = find_occurrence
      result = Tasks::CancelCompletion.new.call(occurrence:)

      notice = result.success? ? t(".success", title: occurrence.task.title) : t(".not_done")
      redirect_back_or_to root_path, notice:, status: :see_other
    end

    private

    def find_occurrence
      policy_scope(TaskOccurrence).find(params[:task_occurrence_id]).tap { |occurrence| authorize occurrence, :complete? }
    end
  end
end
