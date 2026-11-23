require "rails_helper"

RSpec.describe Tasks::AddSuggestions do
  include ActiveSupport::Testing::TimeHelpers

  let(:dishwasher) { create(:equipment, kind: "dishwasher", name: "Lave-vaisselle") }

  around { |example| travel_to(Time.zone.parse("2026-11-23 10:00")) { example.run } }

  it "adds the checked suggestions with their texts, rhythm and first date, none for those done when needed" do
    tasks = described_class.new.call(subject: dishwasher, keys: %w[dishwasher.filter dishwasher.salt]).value!

    filter, salt = tasks
    expect(filter).to have_attributes(title: "Nettoyer le filtre", recurrence_type: "sliding",
                                      suggestion_key: "dishwasher.filter")
    expect(filter.instructions).to include("quart de tour")
    expect(filter.pending_occurrence.due_at.to_date).to eq(Date.new(2026, 12, 23)) # one month: nothing today
    expect(salt).to have_attributes(recurrence_type: "on_demand")
    expect(salt.occurrences).to be_empty
  end

  it "opens a yearly suggestion on its next date" do
    pool = create(:equipment, kind: "pool")

    cyclone = described_class.new.call(subject: pool, keys: %w[pool.cyclone_season]).value!.sole

    expect(cyclone.pending_occurrence.due_at.to_date).to eq(Date.new(2027, 11, 1))
    expect(cyclone.recurrence).to have_attributes(anchor_on: Date.new(2027, 11, 1), unit: "years")
  end

  it "adds none when one cannot be added" do
    allow_any_instance_of(Tasks::Add).to receive(:call).and_wrap_original do |original, **args|
      salt = args[:params].with_indifferent_access[:suggestion_key] == "dishwasher.salt"
      salt ? Dry::Monads::Failure[:invalid, nil] : original.call(**args)
    end

    result = described_class.new.call(subject: dishwasher, keys: %w[dishwasher.filter dishwasher.salt])

    expect(result.failure.first).to eq(:invalid)
    expect(dishwasher.tasks.count).to eq(0)
  end

  it "ignores the suggestions of another kind, unknown or already added ones, and says when none is left" do
    described_class.new.call(subject: dishwasher, keys: %w[dishwasher.filter])

    result = described_class.new.call(subject: dishwasher, keys: %w[dishwasher.filter pool.ph bins.yellow nope])

    expect(result.failure.first).to eq(:none_selected)
    expect(dishwasher.tasks.count).to eq(1)
  end
end
