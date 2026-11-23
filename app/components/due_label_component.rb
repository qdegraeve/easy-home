# Due date relative to today: "due yesterday", "today", "tomorrow", "in 4 days" (French labels from I18n).
# Calm by design (UX review): a late task is not shown in red, it is still in the list of today. Red is kept for the
# tasks that must not be missed (critical), on their day and once late.
class DueLabelComponent < ViewComponent::Base
  def initialize(due_at:, critical: false)
    @days = (due_at.to_date - Time.zone.today).to_i
    @critical = critical
  end

  def call
    content_tag(:span, label, class: tone)
  end

  private

  attr_reader :days, :critical

  def tone
    return "font-semibold text-alert" if critical && days <= 0

    "font-semibold text-ink" if days.zero?
  end

  def label
    case days
    when ...0 then t("due_label.overdue", count: -days)
    when 0 then t("due_label.today")
    when 1 then t("due_label.tomorrow")
    else t("due_label.later", count: days)
    end
  end
end
