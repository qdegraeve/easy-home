require "rails_helper"

RSpec.describe "Journal", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  def watered(name, by:, household: self.household, at: Time.current)
    plant = create(:plant, household:, name:)
    task = create(:task, household:, subject: plant)
    task.occurrences.create!(due_at: at.beginning_of_day, status: :done, completed_at: at, completed_by: by)
  end

  def sign_in(user)
    post session_path, params: { email: user.email, password: "passwordpassword" }
  end

  it "lists what was done in the household, newest first, by day and with who did it" do
    other = create(:household_member, household:, role: :member, user: create(:user, email: "alex@example.com")).user
    watered("Basilic", by: user, at: Time.zone.parse("2026-11-16 08:10"))
    watered("Citronnier", by: other, at: Time.zone.parse("2026-11-15 19:02"))
    watered("Voisin", by: create(:user), household: create(:household))
    sign_in(user)

    get journal_path

    text = response.parsed_body.text.squish
    expect(text).to include("Basilic Arrosé · par vous · 8 h 10", "Citronnier Arrosé · par Alex · 19 h 02")
    expect(text.index("Basilic")).to be < text.index("Citronnier")
    expect(text).not_to include("Voisin")
  end

  it "says what the rain did, with no one as its author" do
    plant = create(:plant, :watered, household:, name: "Basilic", interval_days: 1,
                                     last_watered_at: Time.zone.parse("2026-11-15 08:00"))
    Tasks::Complete.new.call(occurrence: plant.watering_task.pending_occurrence, user: nil, source: :rain)
    Tasks::Postpone.new.call(occurrence: plant.watering_task.reload.pending_occurrence, user: nil, source: :rain)
    sign_in(user)

    get journal_path

    text = response.parsed_body.text.squish
    expect(text).to include(
      "Basilic Arrosé par la pluie · 18 h 30",
      "Basilic Arrosage reporté · par la pluie"
    )
  end

  it "shows nothing to a guest" do
    watered("Basilic", by: user)
    sign_in(create(:household_member, household:, role: :guest).user)

    get journal_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Basilic")
  end

  it "shows only the current household of a user who belongs to two" do
    second = create(:household, name: "Case des Hauts")
    create(:household_member, household: second, user:, role: :member)
    watered("Basilic", by: user)
    watered("Fougère", by: user, household: second)
    sign_in(user)
    post household_selection_path(household)

    get journal_path

    expect(response.body).to include("Basilic")
    expect(response.body).not_to include("Fougère")
  end

  it "keeps the last 60 days, whole days" do
    watered("Basilic", by: user, at: Time.zone.parse("2026-09-18 07:00"))
    watered("Fougère", by: user, at: Time.zone.parse("2026-09-17 21:00"))
    sign_in(user)

    get journal_path

    expect(response.body).to include("Basilic")
    expect(response.body).not_to include("Fougère")
  end

  it "sends a user without household to the household form" do
    sign_in(create(:user))

    [ journal_path, house_path, plants_path ].each do |path|
      get path
      expect(response).to redirect_to(new_household_path), path
    end
  end
end
