# Fake AI analyzer, injected by default in every spec (ADR 0008): no call to Claude in the test suite.
class FakePlantAnalyzer
  ANSWER = {
    "health" => "watch",
    "species" => { "name" => "Citrus limon", "common_name" => "Citronnier", "confidence" => "high" },
    "watering_interval_days" => 4,
    "observations" => "Quelques feuilles jaunissent à la base, sans parasite visible.",
    "actions" => [
      { "title" => "Pailler le pied", "details" => "Une couche de paillis garde la terre fraîche.", "due_in_days" => 3 }
    ]
  }.freeze

  FOLLOW_UP = "Oui, le paillis suffit. Arrosez seulement quand la terre est sèche en surface.".freeze

  # answer= sets the structured answer of an analysis; follow_up= the text answer of a question.
  attr_writer :answer
  attr_accessor :follow_up, :error
  attr_reader :calls

  def initialize
    @answer = ANSWER
    @follow_up = FOLLOW_UP
    @calls = []
  end

  def answer(images:, text:)
    @calls << { images:, text:, follow_up: true }
    raise PlantAnalyzer::Error, error if error

    follow_up
  end

  def analyze(images:, text:)
    @calls << { images:, text: }
    raise PlantAnalyzer::Error, error if error

    @answer
  end
end

RSpec.configure do |config|
  config.before do
    @fake_plant_analyzer = FakePlantAnalyzer.new
    PlantAnalyzer.adapter = @fake_plant_analyzer
  end

  config.after { PlantAnalyzer.adapter = nil }
end
