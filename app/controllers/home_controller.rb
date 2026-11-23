class HomeController < ApplicationController
  # "Bientôt": the tasks of the next days, folded under the ones of today (UX review).
  UPCOMING_DAYS = 3

  def show
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household
    # Something to follow: a plant, or a task of any kind (the house's own, without plants).
    @has_plants = policy_scope(Plant).where(household: @household).active.exists?
    tasks = policy_scope(Task).where(household: @household)
    @has_content = @has_plants || tasks.to_do.exists? || tasks.active.on_demand.exists?
    occurrences = DueOccurrencesQuery.new(policy_scope(TaskOccurrence))
      .call(household_ids: @household.id, days_ahead: UPCOMING_DAYS)
      .includes(task: { subject: :location }).order(:due_at, :id).to_a
    @due_today, @upcoming = occurrences.partition { |occurrence| occurrence.due_at <= Time.zone.today.end_of_day }
    load_done_today
    load_nothing_due_details if @due_today.empty?
    load_rain
  end

  private

  # The last evening's rain, when it watered or postponed plants (Plants::RecordRain): said once at the top, with the
  # plants it concerned, so that a watering gone from the list is not a surprise.
  def load_rain
    rainfall = @household.rainfalls.where(fell_on: Time.zone.yesterday..).order(fell_on: :desc).first
    return unless rainfall&.effect

    status = rainfall.effect == :watered ? :done : :postponed
    names = policy_scope(TaskOccurrence).by_rain.where(status:, completed_at: rainfall.fell_on.all_day)
      .joins(:task).where(tasks: { household_id: @household.id, template_key: Plant::WATERING_TEMPLATE_KEY })
      .includes(task: :subject).filter_map { |occurrence| occurrence.task.subject&.name }
      .sort_by { |name| I18n.transliterate(name).downcase }
    @rain = { rainfall:, names: } if names.any?
  end

  # "Fait aujourd'hui": what was done today in the household, by whom, undoable, so that a task gone from the list
  # can be found again (UX review).
  def load_done_today
    @done_today = policy_scope(TaskOccurrence).done.joins(:task).where(tasks: { household_id: @household.id })
      .where(completed_at: Time.zone.today.all_day).includes(:completed_by, task: :subject)
      .order(completed_at: :desc, id: :desc).to_a
  end

  # For the "nothing to do" state: the next task when none comes in the next days.
  def load_nothing_due_details
    @next_occurrence = policy_scope(TaskOccurrence).pending.joins(:task)
      .where(tasks: { household_id: @household.id, active: true })
      .includes(task: :subject).order(:due_at, :id).first
  end
end
