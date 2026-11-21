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
end
