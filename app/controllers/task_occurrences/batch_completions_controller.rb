module TaskOccurrences
  # Several occurrences at once: the watering line of the home page ("Arroser · 4") and the "Annuler" of a toast.
  class BatchCompletionsController < ApplicationController
    def create
      occurrences = find_occurrences
      return redirect_to(root_path, notice: t(".none_selected"), status: :see_other) if occurrences.empty?

      result = Tasks::CompleteMany.new.call(occurrences:, user: Current.user)

      if result.success?
        done = result.value!
        flash[:undo_ids] = done.map(&:id)
        redirect_to root_path, notice: completed_notice(done), status: :see_other
      else
        redirect_to root_path, notice: t(".nothing_done"), status: :see_other
      end
    end

    def destroy
      result = Tasks::CancelMany.new.call(occurrences: find_occurrences)

      notice = result.success? ? t(".success", count: result.value!.size) : t(".nothing_cancelled")
      redirect_back_or_to root_path, notice:, status: :see_other
    end

    private

    def find_occurrences
      policy_scope(TaskOccurrence).where(id: Array(params[:occurrence_ids])).includes(task: :subject)
        .order(:due_at, :id).to_a.each { |occurrence| authorize occurrence, :complete? }
    end

    def completed_notice(done)
      key = done.all? { |occurrence| occurrence.task.watering? } ? ".waterings" : ".tasks"
      t(key, count: done.size)
    end
  end
end
