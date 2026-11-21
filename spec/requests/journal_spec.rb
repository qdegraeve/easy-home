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
    post session_path, params: { email: user.email, password: "password" }
  end

  it "lists what was done in the household, newest first, by day and with who did it" do
    other = create(:household_member, household:, role: :member, user: create(:user, email: "alex@example.com")).user
    watered("Basilic", by: user, at: Time.zone.parse("2026-11-16 08:10"))
    watered("Citronnier", by: other, at: Time.zone.parse("2026-11-15 19:02"))
    watered("Voisin", by: create(:user), household: create(:household))
    sign_in(user)

    get journal_path

    text = response.parsed_body.text.squish
    expect(text).to include("Arrosage · Basilic par vous · 8 h 10", "Arrosage · Citronnier alex · 19 h 02")
    expect(text.index("Basilic")).to be < text.index("Citronnier")
    expect(text).not_to include("Voisin")
  end

  it "shows nothing to a guest" do
    watered("Basilic", by: user)
    sign_in(create(:household_member, household:, role: :guest).user)

    get journal_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Basilic")
  end
end
