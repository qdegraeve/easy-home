require "rails_helper"

RSpec.describe "Households", type: :request do
  let(:user) { create(:user) }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  describe "GET /households" do
    it "lists only the user's households" do
      create(:membership, user:, household: create(:household, name: "Ma maison"))
      create(:household, name: "Foyer d'un autre")
      sign_in(user)

      get households_path

      expect(response.body).to include("Ma maison")
      expect(response.body).not_to include("Foyer d&#39;un autre")
    end
  end

  describe "POST /households" do
    it "creates the household and makes it the current one" do
      create(:membership, user:, household: create(:household, name: "Appartement"))
      sign_in(user)

      post households_path, params: { household: { name: "Zébu" } }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Zébu", "Foyer « Zébu » créé.")
    end

    it "re-renders the form when the name is missing" do
      sign_in(user)

      post households_path, params: { household: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nom du foyer doit être rempli(e)")
    end
  end

  describe "POST /households/:household_id/selection" do
    it "switches the current household" do
      create(:membership, user:, household: create(:household, name: "Appartement"))
      other = create(:membership, user:, household: create(:household, name: "Zébu")).household
      sign_in(user)

      post household_selection_path(other)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Zébu")
    end

    it "does not let a user select a household they do not belong to" do
      sign_in(user)

      post household_selection_path(create(:household))

      expect(response).to have_http_status(:not_found)
    end
  end
end
