require "rails_helper"

RSpec.describe Plants::RecordRain do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household, :located) }
  let(:garden) { create(:location, :rainy, household:) }
  let(:terrace) { create(:location, household:) } # under a roof: never watered by the rain

  # Every 3 days: last watered on the 13th, due today; on the 14th, due tomorrow; on the 15th, due on the 18th.
  def plant(location:, last_watered_on: 13, interval_days: 3)
    create(
      :plant,
      :watered,
      household:,
      location:,
      interval_days:,
      last_watered_at: Time.zone.parse("2026-11-#{last_watered_on} 08:00")
    )
  end

  def rain(millimeters)
    Weather.rain.result = millimeters
    described_class.new.call(household:)
  end

  def due_on(plant)
    plant.watering_task.pending_occurrence.due_at.to_date.day
  end

  around { |example| travel_to(Time.zone.parse("2026-11-16 22:00")) { example.run } }

  it "records the rain of the day once, asked in the household's time zone" do
    result = rain(14.2)

    expect(result.value!).to have_attributes(fell_on: Date.new(2026, 11, 16), millimeters: 14.2)
    expect(Weather.rain.calls).to eq([ { latitude: household.latitude, longitude: household.longitude,
                                         date: Date.new(2026, 11, 16), time_zone: "Indian/Reunion" } ])
    expect(rain(20).failure.first).to eq(:already_recorded)
    expect(Weather.rain.calls.size).to eq(1)
  end

  it "waters on heavy rain the plants that get it, due today or tomorrow, and restarts them from today" do
    today, tomorrow, later = plant(location: garden), plant(location: garden, last_watered_on: 14),
                             plant(location: garden, last_watered_on: 15)
    sheltered, nowhere = plant(location: terrace), plant(location: nil)

    rain(14)

    [ today, tomorrow ].each do |watered|
      expect(watered.watering_task.occurrences.done.order(:completed_at).last)
        .to have_attributes(source: "rain", completed_by: nil, completed_at: Time.current)
      expect(due_on(watered)).to eq(19)
    end
    expect(due_on(later)).to eq(18)
    expect([ due_on(sheltered), due_on(nowhere) ]).to eq([ 16, 16 ])
    expect(TaskOccurrence.by_rain.count).to eq(2)
  end

  it "postpones on a shower the waterings due today or tomorrow by one day, without counting them done" do
    today, tomorrow, later = plant(location: garden), plant(location: garden, last_watered_on: 14),
                             plant(location: garden, last_watered_on: 15)

    rain(5)

    expect([ due_on(today), due_on(tomorrow), due_on(later) ]).to eq([ 17, 18, 18 ])
    expect(today.watering_task.occurrences.postponed.sole).to have_attributes(source: "rain", completed_by: nil)
    expect(TaskOccurrence.by_rain.done).to be_empty
  end

  it "changes nothing on a drizzle, but records it" do
    watered = plant(location: garden)

    expect(rain(2).value!.millimeters).to eq(2)
    expect(due_on(watered)).to eq(16)
    expect(TaskOccurrence.by_rain).to be_empty
  end

  it "leaves alone, on a shower too, a watering already done today" do
    daily = plant(location: garden, last_watered_on: 15, interval_days: 1)
    Tasks::Complete.new.call(occurrence: daily.watering_task.pending_occurrence, user: create(:user))

    rain(5)

    expect(due_on(daily)).to eq(17)
    expect(daily.watering_task.occurrences.postponed).to be_empty
  end

  it "applies the rain again after a restart in the middle, without touching twice what it already did" do
    done, left = plant(location: garden), plant(location: garden)
    household.rainfalls.create!(fell_on: Date.new(2026, 11, 16), millimeters: 5) # recorded, then the job stopped
    Tasks::Postpone.new.call(occurrence: done.watering_task.pending_occurrence, user: nil, source: :rain)

    result = described_class.new.call(household:)

    expect(result.value!.applied_at).to eq(Time.current)
    expect([ due_on(done), due_on(left) ]).to eq([ 17, 17 ])
    expect(Weather.rain.calls).to be_empty
    expect(described_class.new.call(household:).failure.first).to eq(:already_recorded)
  end

  it "leaves alone a watering already done today and the plants put away" do
    daily = plant(location: garden, last_watered_on: 15, interval_days: 1)
    Tasks::Complete.new.call(occurrence: daily.watering_task.pending_occurrence, user: create(:user))
    archived = plant(location: garden)
    Plants::Archive.new.call(plant: archived)

    rain(30)

    expect(daily.watering_task.occurrences.by_rain).to be_empty
    expect(due_on(daily)).to eq(17)
    expect(archived.watering_task.occurrences.by_rain).to be_empty
  end

  it "is undone like a manual watering: the open one is due again as before" do
    watered = plant(location: garden)
    rain(14)

    Tasks::CancelCompletion.new.call(occurrence: watered.watering_task.occurrences.by_rain.sole)

    expect(due_on(watered)).to eq(16)
  end

  it "does nothing for a household without an address or when the weather is unknown" do
    unlocated = create(:household)
    expect(described_class.new.call(household: unlocated).failure.first).to eq(:not_located)

    expect(rain(nil).failure.first).to eq(:unavailable)
    expect(household.rainfalls).to be_empty
  end
end
