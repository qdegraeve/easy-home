require "rails_helper"

RSpec.describe TaskRowComponent, type: :component do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  let(:plant) { create(:plant, :watered, name: "Citronnier", interval_days: 3) }
  let(:occurrence) { plant.watering_task.pending_occurrence.tap { |o| o.update!(due_at: Date.new(2026, 11, 15)) } }

  it "says what to do and when, with a round done button named for screen readers" do
    render_inline(described_class.new(occurrence:, title: "Citronnier", href: "/plants/1", detail: "Arrosage"))

    expect(page).to have_link("Citronnier", href: "/plants/1")
    expect(page).to have_text("Arrosage · prévu hier")
    expect(page).to have_button("Arrosée : Citronnier")
  end

  it "names the button of a task without subject (bins, to come) by its title" do
    task = create(:task, subject: nil, title: "Sortir la poubelle jaune", template_key: nil, recurrence_type: :once,
                         recurrence_config: { "due_on" => "2026-11-16" })
    occurrence = task.occurrences.create!(due_at: Date.new(2026, 11, 16).in_time_zone)

    render_inline(described_class.new(occurrence:, title: task.title, detail: "Une fois"))

    expect(page).to have_button("Fait : Sortir la poubelle jaune")
  end

  it "replaces the button by a calm label once done today, and shows the extra actions" do
    render_inline(described_class.new(occurrence:, title: "Citronnier", detail: "Arrosage", done_today: true)) do |row|
      row.with_actions { "Modifier" }
    end

    expect(page).to have_no_button("Arrosée : Citronnier")
    expect(page).to have_text("Arrosée aujourd'hui")
    expect(page).to have_text("Modifier")
    expect(page).to have_no_link("Citronnier")
  end
end
