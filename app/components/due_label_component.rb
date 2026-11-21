# Due date relative to today: "2 days late", "today", "tomorrow", "in 4 days" (French labels from I18n).
class DueLabelComponent < ViewComponent::Base
  def initialize(due_at:)
    @days = (due_at.to_date - Time.zone.today).to_i
  end

  def call
    content_tag(:span, label, class: overdue? ? "font-semibold text-alert" : nil)
  end

  private

  attr_reader :days

  def overdue?
    days.negative?
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
