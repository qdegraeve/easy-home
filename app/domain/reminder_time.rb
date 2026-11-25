# The time of a reminder (ADR 0017), stored in minutes after midnight: "19 h", "7 h 30"; said "ce soir 19 h" from the
# evening on, "à 14 h" before.
module ReminderTime
  EVENING = 18 * 60

  def self.label(minute)
    I18n.t(minute >= EVENING ? "reminder_time.evening" : "reminder_time.day", time: clock(minute))
  end

  def self.clock(minute)
    hours, minutes = minute.divmod(60)
    return I18n.t("reminder_time.hours", hours:) if minutes.zero?

    I18n.t("reminder_time.hours_minutes", hours:, minutes: format("%02d", minutes))
  end

  # "19:00" for the form, from 1140.
  def self.to_field(minute)
    format("%02d:%02d", *minute.divmod(60)) if minute
  end

  # 1140 from "19:00"; nil for a blank or invalid value.
  def self.from_field(value)
    hours, minutes = value.to_s.match(/\A(\d{2}):(\d{2})\z/)&.captures&.map(&:to_i)
    (hours * 60) + minutes if hours
  end
end
