# Open occurrences due today or late, of the active tasks of some households: the "À faire aujourd'hui" list and the
# morning digest. With `days_ahead`, also the ones due in the next days (the "Bientôt" list of the home page).
class DueOccurrencesQuery
  def initialize(scope = TaskOccurrence.all)
    @scope = scope
  end

  def call(household_ids:, today: Time.zone.today, days_ahead: 0)
    @scope.pending.joins(:task)
      .where(tasks: { household_id: household_ids, active: true })
      .where(due_at: ..(today + days_ahead).end_of_day)
  end
end
