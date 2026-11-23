# Recurrence engine: plain Ruby, no ActiveRecord. Computes the next due date of a task
# (docs/conception/equipements-et-taches.md).
#
# Common interface:
# - #next_due_at(last_completed_at:, last_due_on: nil, not_before: nil): the due date (TimeWithZone, start of the
#   local day) of the occurrence to open after the last closed one, or nil when there is none left.
#   last_completed_at: the last "done" (nil if never done); last_due_on: due date of the last done or missed
#   occurrence; not_before: earliest acceptable day (only Fixed uses it, to skip the past dates of its rule).
# - #period_days: approximate length of a period (tolerance), nil without one.
# - #dated?: whether the task has due dates (always, until "quand il le faut").
# What happens after a miss depends on the rule and the importance: Tolerance.after_miss.
module Recurrence
  class InvalidConfig < ArgumentError; end

  # Builds the rule from Task#recurrence_type and Task#recurrence_config (string or symbol keys, ISO 8601 dates).
  def self.build(type:, config:)
    config = config.to_h.transform_keys(&:to_s)

    case type.to_s
    when "sliding" then Sliding.new(interval_days: config["interval_days"], start_on: date(config["start_on"]))
    when "once" then Once.new(due_on: date(config["due_on"]))
    when "fixed"
      Fixed.new(anchor_on: date(config["anchor_on"]), interval: config["interval"], unit: config["unit"])
    else raise InvalidConfig, "Unknown recurrence type: #{type.inspect}"
    end
  end

  def self.date(value)
    case value
    when nil, Date then value
    when String then Date.iso8601(value)
    else raise InvalidConfig, "Invalid date: #{value.inspect}"
    end
  rescue Date::Error
    raise InvalidConfig, "Invalid date: #{value.inspect}"
  end
end
