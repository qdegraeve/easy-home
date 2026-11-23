# The journal of a subject (the Historique tab of a plant or an equipment): what was done, postponed or missed for its
# tasks, newest first, with what the lines show preloaded.
class SubjectHistoryQuery
  LIMIT = 30

  def initialize(relation = TaskOccurrence.all)
    @relation = relation
  end

  def call(subject:, limit: LIMIT)
    @relation.where(task: subject.tasks, status: %i[done missed postponed])
      .includes(:completed_by, task: :subject).order(completed_at: :desc, id: :desc).limit(limit)
  end
end
