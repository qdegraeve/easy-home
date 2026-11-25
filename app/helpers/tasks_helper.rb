# Labels of tasks shared by the lists, the sheet and the forms.
module TasksHelper
  # The rhythm of a task, in words: "Une fois", "Tous les 14 jours", "Tous les 3 mois", "Toutes les 2 semaines, le
  # mardi", "Chaque année, le 1er novembre". The weekday and the day of the year come from the anchor of fixed dates.
  def rhythm_label(task)
    rule = task.recurrence
    case rule
    when Recurrence::Once then t("tasks.rhythm.once")
    when Recurrence::OnDemand then t("tasks.rhythm.on_demand")
    when Recurrence::Sliding then t("tasks.rhythm.sliding.#{rule.unit}", count: rule.interval)
    when Recurrence::Fixed
      if rule.weeks?
        t("tasks.rhythm.weeks", count: rule.interval, day: I18n.t("date.day_names")[rule.anchor_on.wday])
      else
        t("tasks.rhythm.years", count: rule.interval, date: day_of_year(rule.anchor_on))
      end
    end
  end

  # The form of a new task of a subject (a plant, an equipment), or of the house when nil.
  def new_task_path_for(subject, **params)
    subject ? new_polymorphic_path([ subject, :task ], **params) : new_task_path(**params)
  end

  private

  # "1er novembre", "15 mai".
  def day_of_year(date)
    day = date.day == 1 ? t("tasks.rhythm.first_day") : date.day.to_s
    "#{day} #{I18n.t('date.month_names')[date.month]}"
  end
end
