# Open occurrences due today or late, of the active tasks of some households: the "À faire aujourd'hui" list and the
# morning digest.
class DueOccurrencesQuery
  def initialize(scope = TaskOccurrence.all)
    @scope = scope
  end

  def call(household_ids:, today: Time.zone.today)
    @scope.pending.joins(:task)
      .where(tasks: { household_id: household_ids, active: true })
      .where(due_at: ..today.end_of_day)
  end
end
