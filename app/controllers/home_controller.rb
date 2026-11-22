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
    load_nothing_due_details if @due_today.empty?
    load_rain
  end

  private

  # The last evening's rain, when it watered or postponed plants (Plants::RecordRain): said once at the top, so that a
  # watering gone from the list is not a surprise.
  def load_rain
    rainfall = @household.rainfalls.where(on: Time.zone.yesterday..).order(on: :desc).first
    return unless rainfall&.effect

    status = rainfall.effect == :watered ? :done : :postponed
    count = policy_scope(TaskOccurrence).by_rain.where(status:, completed_at: rainfall.on.all_day)
      .joins(:task).where(tasks: { household_id: @household.id }).count
    @rain = { rainfall:, count: } if count.positive?
  end

  # For the "nothing to do" state: what was done today, and the next task when none comes in the next days.
  def load_nothing_due_details
    done = policy_scope(TaskOccurrence).done.joins(:task).where(tasks: { household_id: @household.id })
    @done_today_count = done.where(completed_at: Time.zone.today.all_day).count
    @next_occurrence = policy_scope(TaskOccurrence).pending.joins(:task)
      .where(tasks: { household_id: @household.id, active: true })
      .includes(task: :subject).order(:due_at, :id).first
  end
end
