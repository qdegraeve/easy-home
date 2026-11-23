# Catalogue of suggestions (ADR 0016): ready-made tasks described in config/catalogue.yml, their texts in
# config/locales/catalogue.fr.yml. Loaded once; a suggestion is copied into a task when chosen (TaskForm), so that
# changing the catalogue never touches existing tasks.
module Catalogue
  FILE = Rails.root.join("config/catalogue.yml")

  # An immutable suggestion: its key ("bins.yellow"), importance, and recurrence ({ "type", "interval", "unit",
  # "month", "day" }); its texts come from I18n.
  Suggestion = Data.define(:key, :importance, :recurrence) do
    def title
      I18n.t("catalogue.suggestions.#{key}.title")
    end

    def hint
      I18n.t("catalogue.suggestions.#{key}.hint", default: nil)
    end

    def instructions
      I18n.t("catalogue.suggestions.#{key}.instructions", default: nil)
    end

    def critical?
      importance == "critical"
    end

    # The first date offered: a yearly date on its next day; a one-off today; none for weekly fixed dates (the user
    # gives the next collection) nor anything else for now.
    def first_due_on(today:)
      case recurrence["type"]
      when "once" then today
      when "fixed" then next_yearly_date(today) if recurrence["unit"] == "years" && recurrence["month"]
      end
    end

    private

    def next_yearly_date(today)
      date = Date.new(today.year, recurrence["month"], recurrence["day"])
      date < today ? date >> 12 : date
    end
  end

  class << self
    def suggestion(key)
      suggestions[key.to_s] if key.present?
    end

    # The suggestions of a task of the house, but for those already used (existing_keys).
    def household_suggestions(existing_keys: [])
      data.fetch("household_suggestions").map { |key| suggestions.fetch(key) }
        .reject { |suggestion| existing_keys.include?(suggestion.key) }
    end

    def suggestions
      @suggestions ||= data.fetch("suggestions").to_h do |key, entry|
        recurrence = entry.fetch("recurrence").freeze
        [ key, Suggestion.new(key:, importance: entry.fetch("importance"), recurrence:) ]
      end.freeze
    end

    private

    def data
      @data ||= YAML.safe_load_file(FILE).freeze
    end
  end
end
