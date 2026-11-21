require "rails_helper"

RSpec.describe "My house", type: :request do
  let(:household) { create(:household, name: "Maison") }
  let(:user) { create(:household_member, household:, role: :owner).user }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  describe "GET /households/:id/edit" do
    it "shows the address and the locations" do
      create(:location, household:, name: "Terrasse", exposure: :partial_shade, sheltered: true)
      sign_in(user)

      get edit_household_path(household)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.text.squish).to include("Ma maison", "Terrasse", "Mi-ombre · abrité du vent")
    end

    it "asks before deleting a location, telling how many plants lose it" do
      create(:location, household:, name: "Abri")
      create_list(:plant, 1, household:, location: create(:location, household:, name: "Salon"))
      create_list(:plant, 2, household:, location: create(:location, household:, name: "Terrasse"))
      sign_in(user)

      get edit_household_path(household)

      forms = response.parsed_body.css("form[data-confirm-tone=danger]")
      expect(forms.map { |form| form["data-turbo-confirm"] }).to eq([
        "Supprimer l'emplacement « Abri » ?",
        "Supprimer l'emplacement « Salon » ? Sa plante restera, sans emplacement.",
        "Supprimer l'emplacement « Terrasse » ? Ses 2 plantes resteront, sans emplacement."
      ])
    end

    it "does not find the household of someone else" do
      sign_in(user)

      get edit_household_path(create(:household))

      expect(response).to have_http_status(:not_found)
    end

    it "rejects a guest" do
      guest = create(:household_member, household:, role: :guest).user
      sign_in(guest)

      get edit_household_path(household)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /house" do
    it "shows the inventory to everyone, and the places of the house to the owner, not to a guest" do
      create(:plant, :watered, household:, name: "Basilic")
      sign_in(user)
      get house_path
      expect(response.parsed_body.text.squish).to include("Plantes 1 plante", "Adresse et emplacements")

      delete session_path
      sign_in(create(:household_member, household:, role: :guest).user)
      get house_path
      expect(response.body).not_to include("Adresse et emplacements")
    end
  end

  describe "PATCH /households/:id" do
    it "saves the address and the computed altitude" do
      sign_in(user)

      patch household_path(household), params: {
        household: { address: "12 Rue des Exemples", latitude: "-20.9", longitude: "55.45", altitude_m: "" }
      }

      expect(response).to redirect_to(edit_household_path(household))
      expect(household.reload).to have_attributes(address: "12 Rue des Exemples", altitude_m: 320)
    end

    it "renders the form again on an invalid altitude" do
      sign_in(user)

      patch household_path(household), params: { household: { address: "Ici", altitude_m: "99999" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Altitude doit être dans l&#39;intervalle -500..9000")
      expect(household.reload.address).to be_nil
    end

    it "rejects a forged out of range position, without a server error" do
      sign_in(user)

      patch household_path(household), params: { household: { address: "Ici", latitude: "1000", longitude: "55" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(household.reload.latitude).to be_nil
    end

    it "rejects a guest" do
      sign_in(create(:household_member, household:, role: :guest).user)

      patch household_path(household), params: { household: { address: "Ici" } }

      expect(response).to have_http_status(:forbidden)
      expect(household.reload.address).to be_nil
    end
  end

  describe "POST /households/:household_id/locations" do
    it "adds a location" do
      sign_in(user)

      post household_locations_path(household), params: {
        location: { name: "Terrasse", exposure: "full_sun", sheltered: "1" }
      }

      expect(response).to redirect_to(edit_household_path(household))
      expect(household.locations.sole).to have_attributes(name: "Terrasse", exposure: "full_sun", sheltered: true)
    end

    it "renders the page again on a name already taken" do
      create(:location, household:, name: "Terrasse")
      sign_in(user)

      post household_locations_path(household), params: { location: { name: "terrasse", exposure: "shade" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nom est déjà utilisé(e)")
      expect(household.locations.count).to eq(1)
    end

    it "rejects a guest" do
      sign_in(create(:household_member, household:, role: :guest).user)

      post household_locations_path(household), params: { location: { name: "Terrasse", exposure: "shade" } }

      expect(response).to have_http_status(:forbidden)
      expect(household.locations).to be_empty
    end

    it "does not find the household of someone else" do
      sign_in(user)

      post household_locations_path(create(:household)), params: { location: { name: "X", exposure: "shade" } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /locations/:id" do
    it "deletes a location of the household" do
      location = create(:location, household:)
      sign_in(user)

      delete location_path(location)

      expect(response).to redirect_to(edit_household_path(household))
      expect(Location.exists?(location.id)).to be(false)
    end

    it "does not find the location of another household" do
      location = create(:location)
      sign_in(user)

      delete location_path(location)

      expect(response).to have_http_status(:not_found)
      expect(Location.exists?(location.id)).to be(true)
    end

    it "rejects a guest" do
      location = create(:location, household:)
      sign_in(create(:household_member, household:, role: :guest).user)

      delete location_path(location)

      expect(response).to have_http_status(:forbidden)
      expect(Location.exists?(location.id)).to be(true)
    end
  end

  describe "GET /address_suggestions" do
    it "returns the suggested addresses" do
      sign_in(user)

      get address_suggestions_path, params: { q: "12 exemples ville" }

      expect(response.body).to include("12 Rue des Exemples 97400 Ville-Exemple")
      expect(response.body).not_to include("Autre-Exemple")
    end

    it "searches nothing under three characters" do
      sign_in(user)

      get address_suggestions_path, params: { q: "12" }

      expect(response.body.strip).to be_empty
    end

    it "answers 401 when signed out, without redirecting or storing the fragment URL" do
      get address_suggestions_path, params: { q: "12 exemples" }

      expect(response).to have_http_status(:unauthorized)
      expect(session[:return_to_after_authenticating]).to be_nil
    end
  end
end
