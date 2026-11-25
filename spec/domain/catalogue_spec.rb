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

  it "offers the suggestions of an equipment's kind, none for a plant or an equipment of its own" do
    dishwasher = build(:equipment, kind: "dishwasher")

    expect(described_class.suggestions_for(dishwasher, existing_keys: %w[dishwasher.salt]).map(&:key))
      .to eq(%w[dishwasher.filter dishwasher.rinse_aid])
    expect(described_class.suggestions_for(nil).map(&:key)).to include("bins.yellow")
    expect(described_class.suggestions_for(build(:equipment, kind: "other"))).to be_empty
    expect(described_class.suggestions_for(build(:plant))).to be_empty
  end

  it "opens a yearly suggestion on its next date, this year or the next" do
    winter = described_class.suggestion("pool.austral_winter") # 1 May

    expect(winter.first_due_on(today:)).to eq(Date.new(2027, 5, 1))
    expect(winter.first_due_on(today: Date.new(2027, 3, 1))).to eq(Date.new(2027, 5, 1))
    expect(winter.first_due_on(today: Date.new(2027, 5, 1))).to eq(Date.new(2027, 5, 1))
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

  it "gives every kind of equipment a name and a known icon, and refers only to existing suggestions" do
    described_class.equipment_kinds.each do |kind|
      expect(kind.name).not_to include("translation missing"), kind.key
      expect(IconComponent::SHAPES).to have_key(kind.icon.to_s.tr("_", "-")), kind.key
      expect(kind.suggestion_keys - described_class.suggestions.keys).to be_empty, kind.key
    end
    expect(described_class.equipment_kind_keys).to include("other")
  end
end
