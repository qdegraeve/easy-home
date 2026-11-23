require "rails_helper"

# The catalogue is configuration: every suggestion must be usable as is (see config/catalogue.yml).
RSpec.describe Catalogue do
  let(:today) { Date.new(2026, 11, 23) }

  it "gives every suggestion a title, an importance and a rule that makes a valid task" do
    described_class.suggestions.each_value do |suggestion|
      expect(suggestion.title).not_to include("translation missing"), suggestion.key
      expect(%w[flexible critical]).to include(suggestion.importance)
      form = TaskForm.from_suggestion(suggestion, today:)
      form.due_on ||= today
      expect(form).to be_valid, "#{suggestion.key}: #{form.errors.full_messages.to_sentence}"
      expect { Recurrence.build(type: form.recurrence_type, config: form.task_attributes[:recurrence_config]) }
        .not_to raise_error
    end
  end

  it "offers the suggestions of the house in order, but for those already used" do
    expect(described_class.household_suggestions.map(&:key))
      .to eq(%w[bins.yellow bins.grey bins.yellow_back bins.bulky])
    expect(described_class.household_suggestions(existing_keys: %w[bins.yellow]).map(&:key))
      .to eq(%w[bins.grey bins.yellow_back bins.bulky])
  end

  it "prefills the yellow bin: fixed dates every other week, not to be missed, its date left to the user" do
    form = TaskForm.from_suggestion(described_class.suggestion("bins.yellow"), today:)

    expect(form).to have_attributes(
      title: "Sortir la poubelle jaune", recurrence_type: "fixed", interval: 2, unit: "weeks", critical: true,
      due_on: nil, suggestion_key: "bins.yellow"
    )
    expect(form.instructions).to be_present
  end

  it "ignores an unknown key" do
    expect(described_class.suggestion("bins.unknown")).to be_nil
    expect(described_class.suggestion(nil)).to be_nil
  end

  it "offers a rule after the last time one period from today, as if just done" do
    suggestion = described_class::Suggestion.new(
      key: "dishwasher.filter", importance: "flexible", reminder_minute: nil,
      recurrence: { "type" => "sliding", "interval" => 1, "unit" => "months" }
    )

    expect(suggestion.first_due_on(today:)).to eq(Date.new(2026, 12, 23))
  end
end
