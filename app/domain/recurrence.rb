# Recurrence engine: plain Ruby, no ActiveRecord. Computes the next due date of a task.
#
# Common interface: #next_due_at(last_completed_at:) returns the next due date (TimeWithZone, at the start of the
# local day), or nil when there is none left. last_completed_at is nil when the task was never done.
# #due_after_missed(on:) returns the due date of the occurrence that follows a missed one, or nil (see Tolerance).
module Recurrence
  class InvalidConfig < ArgumentError; end

  # Builds the rule from Task#recurrence_type and Task#recurrence_config (string or symbol keys, ISO 8601 dates).
  def self.build(type:, config:)
    config = config.to_h.transform_keys(&:to_s)

    case type.to_s
    when "sliding" then Sliding.new(interval_days: config["interval_days"], start_on: date(config["start_on"]))
    when "once" then Once.new(due_on: date(config["due_on"]))
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
