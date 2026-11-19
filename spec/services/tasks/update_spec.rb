require "rails_helper"

RSpec.describe Tasks::Update do
  include ActiveSupport::Testing::TimeHelpers

  let(:plant) { create(:plant, :watered) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def add(params)
    Tasks::Add.new.call(subject: plant, params:).value!
  end

  it "change le titre et la date d'une tâche unique" do
    task = add(title: "Tailler", recurrence_type: "once", due_on: "2026-11-30")

    described_class.new.call(task:, params: { title: "Tailler les fleurs fanées", due_on: "2026-12-05" })

    expect(task.reload).to have_attributes(
      title: "Tailler les fleurs fanées",
      recurrence_config: { "due_on" => "2026-12-05" }
    )
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-12-05 00:00"))
  end

  it "change l'intervalle et la prochaine fois d'une tâche répétée, sans changer son type" do
    task = add(title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-20", interval_days: "14")

    described_class.new.call(
      task:, params: { title: "Engrais", recurrence_type: "once", due_on: "2026-11-25", interval_days: "21" }
    )

    expect(task.reload).to be_sliding
    expect(task.recurrence.interval_days).to eq(21)
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-25 00:00"))
  end

  it "garde la date de début d'une tâche répétée : annuler toutes ses réalisations y revient" do
    task = add(title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-16", interval_days: "14")
    Tasks::Complete.new.call(occurrence: task.pending_occurrence, user: create(:user))

    described_class.new.call(
      task: task.reload,
      params: { title: "Engrais bio", due_on: "2026-11-30", interval_days: "14" }
    )
    Tasks::CancelCompletion.new.call(occurrence: task.occurrences.done.sole)

    expect(task.reload.recurrence.start_on).to eq(Date.new(2026, 11, 16))
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-16 00:00"))
  end

  it "fait de la date saisie la date de début d'une tâche répétée jamais faite (gardée après restauration)" do
    task = add(title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-20", interval_days: "14")

    described_class.new.call(task:, params: { title: "Engrais", due_on: "2026-11-25", interval_days: "14" })
    Plants::Archive.new.call(plant:)
    Plants::Restore.new.call(plant: plant.reload)

    expect(task.reload.recurrence.start_on).to eq(Date.new(2026, 11, 25))
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-25 00:00"))
  end

  it "refuse une modification sans date au lieu de prendre aujourd'hui" do
    task = add(title: "Tailler", recurrence_type: "once", due_on: "2026-11-30")

    expect(described_class.new.call(task:, params: { title: "Tailler" }).failure.first).to eq(:invalid)
    expect(task.pending_occurrence.reload.due_at).to eq(Time.zone.parse("2026-11-30 00:00"))
  end

  it "refuse une saisie invalide sans rien modifier" do
    task = add(title: "Tailler", recurrence_type: "once", due_on: "2026-11-30")

    result = described_class.new.call(task:, params: { title: "", due_on: "2026-12-05" })

    expect(result.failure.first).to eq(:invalid)
    expect(task.reload.title).to eq("Tailler")
  end
end
