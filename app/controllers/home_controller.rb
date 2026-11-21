class HomeController < ApplicationController
  # "Bientôt": the tasks of the next days, folded under the ones of today (UX review).
  UPCOMING_DAYS = 3

  def show
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household
    @has_plants = policy_scope(Plant).where(household: @household).active.exists?
    occurrences = DueOccurrencesQuery.new(policy_scope(TaskOccurrence))
      .call(household_ids: @household.id, days_ahead: UPCOMING_DAYS)
      .includes(task: { subject: :location }).order(:due_at, :id).to_a
    @due_today, @upcoming = occurrences.partition { |occurrence| occurrence.due_at <= Time.zone.today.end_of_day }
  end
end
