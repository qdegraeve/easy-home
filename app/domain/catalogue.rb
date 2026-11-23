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
      date = yearly_date(today.year)
      date < today ? yearly_date(today.year + 1) : date
    end

    # February 29 falls on the 28th the years without one (as Recurrence::Fixed does).
    def yearly_date(year)
      month, day = recurrence.values_at("month", "day")
      Date.valid_date?(year, month, day) ? Date.new(year, month, day) : Date.new(year, month, -1)
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

    # Loaded once and deeply frozen: shared safely by the threads of Puma.
    def suggestions
      @suggestions ||= Ractor.make_shareable(
        data.fetch("suggestions").to_h do |key, entry|
          [ key, Suggestion.new(key:, importance: entry.fetch("importance"), recurrence: entry.fetch("recurrence")) ]
        end
      )
    end

    private

    def data
      @data ||= Ractor.make_shareable(YAML.safe_load_file(FILE))
    end
  end
end
