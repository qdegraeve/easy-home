module Today
  # Detail of the watering line of the home page: the plants to water today, by location, all checked; unchecking the
  # ones not watered keeps the gesture quick for the usual case.
  class WateringsController < ApplicationController
    def show
      @household = current_household
      return redirect_to(root_path) unless @household

      authorize @household, :show?
      @occurrences = DueOccurrencesQuery.new(policy_scope(TaskOccurrence)).call(household_ids: @household.id)
        .merge(Task.where(template_key: Plant::WATERING_TEMPLATE_KEY))
        .includes(task: { subject: :location }).order(:due_at, :id).to_a
      return redirect_to(root_path, notice: t(".nothing")) if @occurrences.empty?

      @by_location = @occurrences.group_by { |occurrence| occurrence.task.subject.location }
        .sort_by { |location, _| [ location ? 0 : 1, location&.name.to_s ] }
    end
  end
end
