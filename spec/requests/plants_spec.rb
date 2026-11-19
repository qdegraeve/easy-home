require "rails_helper"

RSpec.describe "Plantes", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household, name: "Maison") }
  let(:user) { create(:household_member, household:, role: :member).user }
  let(:guest) { create(:household_member, household:, role: :guest).user }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  describe "GET /" do
    it "liste les plantes à arroser, toutes les plantes par emplacement, et les archivées à part" do
      terrasse = create(:location, household:, name: "Terrasse", exposure: :partial_shade)
      create(:plant, :watered, household:, name: "Basilic", location: terrasse, interval_days: 1,
                               last_watered_at: Time.zone.parse("2026-11-15 08:00"))
      create(:plant, :watered, household:, name: "Aloe", interval_days: 9)
      create(:plant, :watered, household:, name: "Fougère morte", archived_at: Time.current)
      sign_in(user)

      get root_path

      expect(response.body).to include("À arroser aujourd&#39;hui · 1", "Arrosée : Basilic", "Toutes les plantes · 2")
      expect(response.body).to include("Terrasse · ⛅ Mi-ombre", "Sans emplacement", "dans 9 j")
      expect(response.body).to include("Plantes archivées · 1", "Fougère morte")
      expect(response.body).not_to include("Arrosée : Aloe")
    end

    it "ne montre ni plantes ni bouton d'ajout à un invité" do
      create(:plant, :watered, household:, name: "Basilic")
      sign_in(guest)

      get root_path

      expect(response.body).not_to include("Basilic", "Ajouter une plante")
    end
  end

  describe "POST /plants" do
    it "ajoute une plante au foyer actif" do
      sign_in(user)

      post plants_path, params: { plant: { name: "Basilic", watering_interval_days: "2", last_watered_on: "2026-11-16" } }

      plant = household.plants.sole
      expect(response).to redirect_to(plant_path(plant))
      expect(plant.watering_task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-18 00:00"))
    end

    it "réaffiche le formulaire sur un intervalle invalide" do
      sign_in(user)

      post plants_path, params: { plant: { name: "Basilic", watering_interval_days: "0" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Arrosage doit être dans l&#39;intervalle 1..60")
      expect(Plant.count).to eq(0)
    end

    it "refuse un invité" do
      sign_in(guest)

      post plants_path, params: { plant: { name: "Basilic", watering_interval_days: "2" } }

      expect(response).to have_http_status(:forbidden)
      expect(Plant.count).to eq(0)
    end
  end

  describe "GET /plants/:id" do
    it "affiche l'arrosage et le journal" do
      plant = create(:plant, :watered, household:, name: "Basilic", interval_days: 2,
                                       last_watered_at: Time.zone.parse("2026-11-15 08:00"))
      sign_in(user)

      get plant_path(plant)

      expect(response.body).to include("Tous les 2 jours", "Prochain arrosage :", "demain", "Dernier arrosage : dim 15 nov.")
    end

    it "ne trouve pas la plante d'un autre foyer" do
      sign_in(user)

      get plant_path(create(:plant))

      expect(response).to have_http_status(:not_found)
    end

    it "ne montre pas la plante à un invité" do
      sign_in(guest)

      get plant_path(create(:plant, household:))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /plants/:id" do
    let(:plant) { create(:plant, :watered, household:, name: "Basilic", interval_days: 2) }

    it "enregistre le nouvel intervalle" do
      sign_in(user)

      patch plant_path(plant), params: { plant: { name: "Basilic", watering_interval_days: "4" } }

      expect(response).to redirect_to(plant_path(plant))
      expect(plant.watering_task.reload.recurrence.interval_days).to eq(4)
    end

    it "réaffiche le formulaire sans nom" do
      sign_in(user)

      patch plant_path(plant), params: { plant: { name: "", watering_interval_days: "4" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nom doit être rempli(e)")
      expect(plant.reload.name).to eq("Basilic")
    end
  end

  describe "archivage et suppression" do
    let(:plant) { create(:plant, :watered, household:, name: "Basilic") }

    it "archive puis restaure une plante" do
      sign_in(user)

      post plant_archive_path(plant)
      expect(plant.reload).to be_archived

      delete plant_archive_path(plant)
      expect(plant.reload).not_to be_archived
    end

    it "supprime une plante et son historique" do
      sign_in(user)

      delete plant_path(plant)

      expect(response).to redirect_to(root_path)
      expect(Plant.exists?(plant.id)).to be(false)
      expect(TaskOccurrence.count).to eq(0)
    end

    it "ne trouve pas la plante d'un autre foyer" do
      other = create(:plant, :watered)
      sign_in(user)

      delete plant_path(other)
      post plant_archive_path(other)

      expect(response).to have_http_status(:not_found)
      expect(other.reload).not_to be_archived
    end
  end

  describe "POST /task_occurrences/:id/completion" do
    let(:plant) { create(:plant, :watered, household:, name: "Basilic", interval_days: 2) }
    let(:occurrence) { plant.watering_task.pending_occurrence }

    it "enregistre l'arrosage et revient à la page d'origine" do
      sign_in(user)

      post task_occurrence_completion_path(occurrence), headers: { "HTTP_REFERER" => plant_url(plant) }

      expect(response).to redirect_to(plant_url(plant))
      expect(flash[:notice]).to eq("Arrosage noté pour « Basilic ».")
      expect(occurrence.reload).to be_done
    end

    it "ne compte qu'un arrosage sur un double appui" do
      sign_in(user)

      2.times { post task_occurrence_completion_path(occurrence) }

      expect(flash[:notice]).to eq("C'était déjà fait.")
      expect(plant.watering_task.occurrences.done.count).to eq(2)
    end

    it "refuse l'échéance d'un autre foyer" do
      other = create(:plant, :watered).watering_task.pending_occurrence
      sign_in(user)

      post task_occurrence_completion_path(other)

      expect(response).to have_http_status(:not_found)
      expect(other.reload).to be_pending
    end
  end
end
