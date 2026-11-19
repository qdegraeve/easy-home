require "rails_helper"

RSpec.describe Tasks::Reschedule do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  it "ne crée aucune échéance pour une tâche arrêtée" do
    task = create(:task, active: false)

    expect(described_class.new.call(task:).value!).to be_nil
    expect(task.occurrences).to be_empty
  end

  it "retire l'échéance ouverte d'une tâche unique déjà faite" do
    task = create(:task, recurrence_type: :once, recurrence_config: { "due_on" => "2026-11-20" })
    create(:task_occurrence, :done, task:)
    create(:task_occurrence, task:)

    expect(described_class.new.call(task:).value!).to be_nil
    expect(task.occurrences.pending).to be_empty
  end

  it "part de la date de début d'une tâche répétée jamais faite" do
    task = create(:task, recurrence_config: { "interval_days" => 14, "start_on" => "2026-11-25" })

    expect(described_class.new.call(task:).value!.due_at).to eq(Time.zone.parse("2026-11-25 00:00"))
  end

  it "part de maintenant quand la tâche n'a jamais été faite" do
    task = create(:task, interval_days: 2)

    expect(described_class.new.call(task:).value!.due_at).to eq(Time.zone.parse("2026-11-18 00:00"))
  end
end
