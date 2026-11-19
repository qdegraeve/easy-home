require "rails_helper"

RSpec.describe Tasks::Reschedule do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  it "ne crée aucune échéance pour une tâche arrêtée" do
    task = create(:task, active: false)

    expect(described_class.new.call(task:).value!).to be_nil
    expect(task.occurrences).to be_empty
  end

  it "part de maintenant quand la tâche n'a jamais été faite" do
    task = create(:task, interval_days: 2)

    expect(described_class.new.call(task:).value!.due_at).to eq(Time.zone.parse("2026-11-18 00:00"))
  end
end
