require "rails_helper"

RSpec.describe "Ma maison", type: :request do
  let(:household) { create(:household, name: "Maison") }
  let(:user) { create(:household_member, household:, role: :owner).user }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  describe "GET /households/:id/edit" do
    it "affiche l'adresse et les emplacements" do
      create(:location, household:, name: "Terrasse", exposure: :partial_shade, sheltered: true)
      sign_in(user)

      get edit_household_path(household)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ma maison", "Terrasse", "⛅ Mi-ombre", "abrité du vent")
    end

    it "ne trouve pas le foyer d'un autre" do
      sign_in(user)

      get edit_household_path(create(:household))

      expect(response).to have_http_status(:not_found)
    end

    it "refuse un invité" do
      guest = create(:household_member, household:, role: :guest).user
      sign_in(guest)

      get edit_household_path(household)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /households/:id" do
    it "enregistre l'adresse et l'altitude calculée" do
      sign_in(user)

      patch household_path(household), params: {
        household: { address: "12 Rue des Exemples", latitude: "-20.9", longitude: "55.45", altitude_m: "" }
      }

      expect(response).to redirect_to(edit_household_path(household))
      expect(household.reload).to have_attributes(address: "12 Rue des Exemples", altitude_m: 320)
    end

    it "réaffiche le formulaire sur une altitude invalide" do
      sign_in(user)

      patch household_path(household), params: { household: { address: "Ici", altitude_m: "99999" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Altitude")
    end
  end

  describe "POST /households/:household_id/locations" do
    it "ajoute un emplacement" do
      sign_in(user)

      post household_locations_path(household), params: {
        location: { name: "Terrasse", exposure: "full_sun", sheltered: "1" }
      }

      expect(response).to redirect_to(edit_household_path(household))
      expect(household.locations.sole).to have_attributes(name: "Terrasse", exposure: "full_sun", sheltered: true)
    end

    it "réaffiche la page sur un nom déjà pris" do
      create(:location, household:, name: "Terrasse")
      sign_in(user)

      post household_locations_path(household), params: { location: { name: "terrasse", exposure: "shade" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(household.locations.count).to eq(1)
    end

    it "ne trouve pas le foyer d'un autre" do
      sign_in(user)

      post household_locations_path(create(:household)), params: { location: { name: "X", exposure: "shade" } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /locations/:id" do
    it "supprime un emplacement du foyer" do
      location = create(:location, household:)
      sign_in(user)

      delete location_path(location)

      expect(response).to redirect_to(edit_household_path(household))
      expect(Location.exists?(location.id)).to be(false)
    end

    it "ne trouve pas l'emplacement d'un autre foyer" do
      location = create(:location)
      sign_in(user)

      delete location_path(location)

      expect(response).to have_http_status(:not_found)
      expect(Location.exists?(location.id)).to be(true)
    end
  end

  describe "GET /address_suggestions" do
    it "renvoie les adresses proposées" do
      sign_in(user)

      get address_suggestions_path, params: { q: "12 exemples ville" }

      expect(response.body).to include("12 Rue des Exemples 97400 Ville-Exemple")
      expect(response.body).not_to include("Autre-Exemple")
    end

    it "ne cherche rien sous trois caractères" do
      sign_in(user)

      get address_suggestions_path, params: { q: "12" }

      expect(response.body.strip).to be_empty
    end

    it "exige une connexion" do
      get address_suggestions_path, params: { q: "12 exemples" }

      expect(response).to redirect_to(new_session_path)
    end
  end
end
