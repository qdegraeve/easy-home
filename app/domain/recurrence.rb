# Moteur de récurrence : Ruby pur, sans ActiveRecord. Calcule la prochaine échéance d'une tâche.
#
# Interface commune : #next_due_at(last_completed_at:) renvoie la prochaine échéance (TimeWithZone, au début du jour
# local), ou nil quand il n'y en a plus. last_completed_at vaut nil si la tâche n'a jamais été faite.
module Recurrence
  class InvalidConfig < ArgumentError; end

  # Construit la règle depuis Task#recurrence_type et Task#recurrence_config (clés chaîne ou symbole, dates ISO 8601).
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
