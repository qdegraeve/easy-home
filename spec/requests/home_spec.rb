require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "redirects a visitor to the sign in form" do
      get root_path

      expect(response).to redirect_to(new_session_path)
    end

    it "renders the household page for a signed in user" do
      user = create(:user, :with_household)
      post session_path, params: { email: user.email, password: "password" }

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Maison de test", "Aujourd&#39;hui", "Réglages")
    end

    it "sends a user without household to the household form" do
      user = create(:user)
      post session_path, params: { email: user.email, password: "password" }

      get root_path

      expect(response).to redirect_to(new_household_path)
    end

    it "shows the first household by name when none is selected" do
      user = create(:user)
      create(:household_member, user:, household: create(:household, name: "Zébu"))
      create(:household_member, user:, household: create(:household, name: "Appartement"))
      post session_path, params: { email: user.email, password: "password" }

      get root_path

      expect(response.body).to include("Appartement")
    end
  end

  describe "GET / with nothing to do today" do
    include ActiveSupport::Testing::TimeHelpers

    around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

    let(:user) { create(:user, :with_household) }

    before { post session_path, params: { email: user.email, password: "password" } }

    it "says so, with the next task when none comes in the next days" do
      create(
        :plant,
        :watered,
        household: user.households.sole,
        name: "Cactus",
        interval_days: 10,
        last_watered_at: Time.zone.parse("2026-11-10 08:00")
      )

      get root_path

      text = response.parsed_body.text.squish
      expect(text).to include(
        "Rien à faire aujourd'hui.",
        "Tout est à jour dans la maison.",
        "Prochaine tâche : Arroser Cactus, dans 4 j",
        "Voir les plantes"
      )
    end

    it "counts what was done today and leads to the journal" do
      plant = create(
        :plant,
        :watered,
        household: user.households.sole,
        interval_days: 3,
        last_watered_at: Time.zone.parse("2026-11-13 08:00")
      )
      Tasks::Complete.new.call(occurrence: plant.watering_task.pending_occurrence, user:)

      get root_path

      expect(response.parsed_body.text.squish).to include("Une tâche faite aujourd'hui. Bravo !", "Voir le journal")
    end
  end

  describe "GET / after rain" do
    include ActiveSupport::Testing::TimeHelpers

    let(:user) { create(:user, :with_household) }
    let(:household) { user.households.sole.tap { |home| home.update!(latitude: -20.9, longitude: 55.45) } }

    def rain(millimeters, at:)
      travel_to(Time.zone.parse(at)) do
        Weather.rain.result = millimeters
        Plants::RecordRain.new.call(household:)
      end
    end

    before do
      garden = create(:location, :rainy, household:)
      2.times do
        create(:plant, :watered, household:, location: garden, last_watered_at: Time.zone.parse("2026-11-13 08:00"))
      end
      post session_path, params: { email: user.email, password: "password" }
    end

    it "says the next day that a shower postponed the waterings, then no more" do
      rain(6.4, at: "2026-11-16 22:00")

      travel_to(Time.zone.parse("2026-11-17 07:00")) { get root_path }
      expect(response.parsed_body.text.squish)
        .to include("Averse hier (6 mm) : arrosage de 2 plantes décalé d'un jour.")

      travel_to(Time.zone.parse("2026-11-18 07:00")) { get root_path }
      expect(response.body).not_to include("Averse")
    end

    it "says nothing for a drizzle, nor for the rain of another household" do
      rain(1, at: "2026-11-16 22:00")
      other = create(:household, :located)
      create(:household_member, household: other)
      create(:plant, :watered, household: other, location: create(:location, :rainy, household: other),
                               last_watered_at: Time.zone.parse("2026-11-13 08:00"))
      travel_to(Time.zone.parse("2026-11-16 22:00")) do
        Weather.rain.result = 30
        expect(Plants::RecordRain.new.call(household: other)).to be_success
      end
      expect(TaskOccurrence.by_rain.done.count).to eq(1)

      travel_to(Time.zone.parse("2026-11-17 07:00")) { get root_path }

      expect(response.body).not_to include("Pluie", "Averse")
    end
  end
end
