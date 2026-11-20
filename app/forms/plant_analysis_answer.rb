# The structured answer of the AI, checked strictly before anything is stored (ADR 0008): known values only,
# bounded lengths, integers within range. An answer that does not fit makes the analysis fail.
class PlantAnalysisAnswer
  include ActiveModel::Validations

  HEALTHS = %w[ok watch act].freeze
  CONFIDENCES = %w[low medium high].freeze

  attr_reader :raw

  validate :answer_must_fit_the_schema

  def initialize(raw)
    @raw = raw.is_a?(Hash) ? raw.deep_stringify_keys : {}
  end

  def attributes
    species = raw["species"]
    {
      health: raw["health"],
      species_name: species["name"].strip.presence,
      species_common_name: species["common_name"].strip.presence,
      species_confidence: species["confidence"],
      watering_interval_days: raw["watering_interval_days"],
      observations: raw["observations"].strip,
      actions: raw["actions"].map { |action| action.slice("title", "details", "due_in_days") }
    }
  end

  private

  def answer_must_fit_the_schema
    problems = [
      (:health unless HEALTHS.include?(raw["health"])),
      (:species unless species_valid?(raw["species"])),
      (:watering_interval_days unless integer_in?(raw["watering_interval_days"], 1..60)),
      (:observations unless text?(raw["observations"], 2000)),
      (:actions unless actions_valid?(raw["actions"]))
    ].compact
    problems.each { |attribute| errors.add(attribute, :invalid) }
  end

  def species_valid?(species)
    species.is_a?(Hash) && text?(species["name"], 100) && text?(species["common_name"], 100) &&
      CONFIDENCES.include?(species["confidence"])
  end

  def actions_valid?(actions)
    actions.is_a?(Array) && actions.size <= 5 && actions.all? do |action|
      action.is_a?(Hash) && text?(action["title"], 100, required: true) && text?(action["details"], 500) &&
        integer_in?(action["due_in_days"], 0..60)
    end
  end

  def text?(value, max, required: false)
    value.is_a?(String) && value.length <= max && (!required || value.strip.present?)
  end

  def integer_in?(value, range)
    value.is_a?(Integer) && range.cover?(value)
  end
end
