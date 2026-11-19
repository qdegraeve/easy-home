# Moteur de récurrence : Ruby pur, sans ActiveRecord. Calcule la prochaine échéance d'une tâche.
module Recurrence
  class InvalidConfig < ArgumentError; end

  # Construit la règle depuis Task#recurrence_type et Task#recurrence_config (clés chaîne ou symbole).
  def self.build(type:, config:)
    config = config.to_h.transform_keys(&:to_s)

    case type.to_s
    when "sliding" then Sliding.new(interval_days: config["interval_days"])
    else raise InvalidConfig, "Unknown recurrence type: #{type.inspect}"
    end
  end
end
