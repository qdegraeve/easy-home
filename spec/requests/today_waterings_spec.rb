require "rails_helper"

RSpec.describe "Watering of the day", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  def due_plant(name, household: self.household, location: nil)
    create(
      :plant,
      :watered,
      household:,
      name:,
      location:,
      interval_days: 3,
      last_watered_at: Time.zone.parse("2026-11-12 08:00")
    )
  end

  it "lists the plants to water today by location, all checked, without those of another household" do
    due_plant("Basilic", location: create(:location, household:, name: "Terrasse"))
    due_plant("Aloe")
    due_plant("Voisin", household: create(:household))
    sign_in(user)

    get today_watering_path

    page = response.parsed_body
    expect(page.css("section h2").map(&:text).map(&:squish)).to eq([ "Terrasse", "Sans emplacement" ])
    expect(page.css("input[type=checkbox][checked]").size).to eq(2)
    expect(response.body).not_to include("Voisin")
  end

  it "goes back to the home page when there is nothing to water" do
    sign_in(user)

    get today_watering_path

    expect(response).to redirect_to(root_path)
    expect(flash[:notice]).to eq("Rien à arroser aujourd'hui.")
  end

  it "shows nothing to do to a guest, who cannot do the tasks" do
    due_plant("Basilic")
    sign_in(create(:household_member, household:, role: :guest).user)

    get today_watering_path

    expect(response).to redirect_to(root_path)
  end

  it "sends a user without household to the home page" do
    sign_in(create(:user))

    get today_watering_path

    expect(response).to redirect_to(root_path)
  end
end
