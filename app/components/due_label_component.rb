# Due date relative to today: "due yesterday", "today", "tomorrow", "in 4 days" (French labels from I18n).
# Calm by design (UX review): a late task is not shown in red, it is still in the list of today. Red will be kept for
# the tasks that must not be missed (bins), with the task importance (UX review, PR 10).
class DueLabelComponent < ViewComponent::Base
  def initialize(due_at:)
    @days = (due_at.to_date - Time.zone.today).to_i
  end

  def call
    content_tag(:span, label, class: days.zero? ? "font-semibold text-ink" : nil)
  end

  private

  attr_reader :days

  def label
    case days
    when ...0 then t("due_label.overdue", count: -days)
    when 0 then t("due_label.today")
    when 1 then t("due_label.tomorrow")
    else t("due_label.later", count: days)
    end
  end
end
