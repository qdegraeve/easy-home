require "rails_helper"

RSpec.describe TaskListComponent, type: :component do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  let(:household) { create(:household) }

  def due_watering(name, location: nil)
    plant = create(
      :plant,
      :watered,
      household:,
      name:,
      location:,
      interval_days: 3,
      last_watered_at: Time.zone.parse("2026-11-13 08:00")
    )
    plant.watering_task.pending_occurrence
  end

  it "puts all the waterings on one line, counted by location, and keeps the other tasks apart" do
    terrace = create(:location, household:, name: "Terrasse")
    occurrences = [
      due_watering("Basilic", location: terrace),
      due_watering("Menthe", location: terrace),
      due_watering("Aloe")
    ]
    pruning = create(
      :task,
      household:,
      subject: occurrences.first.task.subject,
      title: "Tailler",
      template_key: nil,
      recurrence_type: :once,
      recurrence_config: { "due_on" => "2026-11-16" }
    )
    occurrences << pruning.occurrences.create!(due_at: Date.new(2026, 11, 16).in_time_zone)

    render_inline(described_class.new(occurrences:, title: "Aujourd'hui", id: "today"))

    expect(page.all("li").size).to eq(2)
    expect(page).to have_text("Terrasse 2 · sans emplacement 1")
    expect(page).to have_button("Tout arroser : 3 plantes")
    expect(page).to have_button("Fait : Tailler (Basilic)")
  end

  it "keeps a single watering on its own line, with the plant's name" do
    render_inline(described_class.new(occurrences: [ due_watering("Aloe") ], title: "Aujourd'hui", id: "today"))

    expect(page).to have_button("Arrosée : Aloe")
    expect(page).to have_no_text("Tout arroser")
  end

  it "shows the empty state when there is nothing" do
    render_inline(described_class.new(occurrences: [], title: "Aujourd'hui", id: "today", empty: "Rien à faire."))

    expect(page).to have_text("Rien à faire.")
  end

  it "puts the tasks that must not be missed first, marked in red" do
    occurrences = [ due_watering("Basilic"), due_watering("Menthe") ]
    plant = occurrences.first.task.subject
    treatment = create(:task, household:, subject: plant, title: "Traitement", template_key: nil, importance: :critical,
                              recurrence_type: :once, recurrence_config: { "due_on" => "2026-11-16" })
    occurrences << treatment.occurrences.create!(due_at: Date.new(2026, 11, 16).in_time_zone)

    render_inline(described_class.new(occurrences:, title: "À faire", id: "due"))

    rows = page.all("li")
    expect(rows.first).to have_text("Traitement")
    expect(rows.first).to have_css(".text-alert", text: "aujourd'hui")
    expect(rows.last).to have_text("Arroser")
  end
end
