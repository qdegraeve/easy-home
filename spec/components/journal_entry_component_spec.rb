require "rails_helper"

RSpec.describe JournalEntryComponent, type: :component do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  let(:me) { create(:user) }
  let(:household) { create(:household) }
  let(:plant) { create(:plant, household:, name: "Citronnier") }
  let(:watering) { create(:task, household:, subject: plant) }
  let(:pruning) do
    create(:task, household:, subject: plant, title: "Tailler", template_key: nil, recurrence_type: :once,
                  recurrence_config: { "due_on" => "2026-11-16" })
  end
  let(:bins) do
    create(:task, household:, subject: nil, title: "Poubelle jaune", template_key: nil, recurrence_type: :once,
                  recurrence_config: { "due_on" => "2026-11-16" })
  end

  def entry(task, status: :done, by: nil, source: :manual)
    task.occurrences.create!(due_at: Date.new(2026, 11, 15).in_time_zone, status:, completed_at: Time.current,
                             completed_by: by, source:)
  end

  def line(occurrence)
    render_inline(described_class.new(entry: occurrence, user: me)).text.squish
  end

  it "starts with what changes, then what happened, who and when" do
    expect(line(entry(watering, by: me))).to start_with("Citronnier Arrosé · par vous · 18 h 30")
    expect(line(entry(pruning, by: me))).to start_with("Tailler Citronnier · par vous · 18 h 30")
    expect(line(entry(bins, by: me))).to start_with("Poubelle jaune par vous · 18 h 30")
    expect(line(entry(watering))).to start_with("Citronnier Arrosé · 18 h 30")
    expect(line(entry(watering, source: :rain))).to start_with("Citronnier Arrosé par la pluie · 18 h 30")
  end

  it "names another member by the start of the e-mail" do
    sam = create(:user, email: "sam.dupont@example.com")

    expect(line(entry(watering, by: sam))).to include("par Sam ·")
  end

  it "keeps postponed and missed lines discreet, with nothing to undo" do
    expect(line(entry(pruning, status: :postponed, by: me))).to eq("Tailler Citronnier · Échéance reportée · par vous")
    expect(line(entry(watering, status: :postponed, source: :rain)))
      .to eq("Citronnier Arrosage reporté · par la pluie")
    expect(line(entry(watering, status: :missed))).to eq("Citronnier Arrosage non fait, prévu le dim 15 nov.")
    expect(line(entry(bins, status: :missed))).to eq("Poubelle jaune Non fait, prévu le dim 15 nov.")
    expect(page).to have_no_button
  end

  it "names the line in the undo button, and promises no new date for a stopped task" do
    render_inline(described_class.new(entry: entry(bins, by: me), user: me))
    expect(page).to have_button("Annuler « Poubelle jaune » du lun 16 nov.")
    expect(page).to have_css("form[data-turbo-confirm$='La prochaine échéance sera recalculée.']")

    watering.update!(active: false)
    render_inline(described_class.new(entry: entry(watering, by: me), user: me))
    expect(page).to have_css("form[data-turbo-confirm='Retirer « Arrosage · Citronnier » (lun 16 nov.) du journal ?']")
    expect(page).to have_css("form[data-confirm-cancel='Garder'][data-confirm-button='Retirer']")
  end
end
