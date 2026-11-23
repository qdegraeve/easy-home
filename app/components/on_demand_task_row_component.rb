# A task done when needed (Recurrence::OnDemand) in a list: what to do and when it was last done ("dernière fois :
# sam 14 nov.", "jamais fait"), opening its sheet, with a "Fait" button that records it (Tasks::RecordDone); once done
# today, a calm "done today" instead. Never in "Aujourd'hui": it has no due date.
#
#   render OnDemandTaskRowComponent.new(task:, last_done_at: nil)
class OnDemandTaskRowComponent < ViewComponent::Base
  def initialize(task:, last_done_at:)
    @task = task
    @last_done_at = last_done_at
  end

  private

  attr_reader :task, :last_done_at

  def done_today?
    last_done_at&.to_date == Time.zone.today
  end

  # Like TaskRowComponent: the mark of its subject, the house for a task of the house.
  def mark_icon
    return :house unless task.subject

    task.subject.try(:icon) || :list_todo
  end

  # "Marquer comme fait : Remettre du sel (Lave-vaisselle)", like the other rows.
  def done_label
    return t("task_row_component.done", title: task.title) unless task.subject

    t("task_row_component.done_with_subject", title: task.title, subject: task.subject.name)
  end

  def last_done_label
    return t(".never") unless last_done_at

    t(".last_done", date: l(last_done_at.to_date, format: :day))
  end
end
