# Échéance relative à aujourd'hui : « en retard de 2 j », « aujourd'hui », « demain », « dans 4 j ».
class DueLabelComponent < ViewComponent::Base
  def initialize(due_at:)
    @days = (due_at.to_date - Time.zone.today).to_i
  end

  def call
    content_tag(:span, label, class: overdue? ? "font-semibold text-red-700" : nil)
  end

  private

  attr_reader :days

  def overdue? = days.negative?

  def label
    case days
    when ...0 then t("due_label.overdue", count: -days)
    when 0 then t("due_label.today")
    when 1 then t("due_label.tomorrow")
    else t("due_label.later", count: days)
    end
  end
end
