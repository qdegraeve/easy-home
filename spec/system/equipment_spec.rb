require "rails_helper"

# Critical journey: an equipment and its upkeep (see docs/tests.md and docs/conception/equipements-et-taches.md).
# Added from the "+" of Maison with what is good to know, a task added from its page with how to do it, done from
# "Aujourd'hui" where it shows the equipment's name, then the equipment deleted with its tasks.
RSpec.describe "Equipment", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "adds an equipment, a task of its upkeep, does it from Aujourd'hui, then deletes the equipment" do
    create(:user, :with_household, email: "quentin@example.com", password: "secret-password")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    go_to_tab("Maison")
    click_on "Ajouter"
    click_on "Un équipement"
    find("label", text: "Climatisation").click
    fill_in "Nom", with: "Clim de la chambre"
    find("summary", text: "Ajouter ce qui est bon à savoir").click
    fill_in "À savoir", with: "Filtre réf. F-42."
    click_on "Ajouter l'équipement"
    expect(page).to have_content("Équipement « Clim de la chambre » ajouté.")
    expect(page).to have_content("Filtre réf. F-42.")

    click_on "Ajouter une tâche"
    fill_in "Tâche", with: "Nettoyer le filtre"
    fill_in "Date", with: Date.new(2026, 11, 16)
    fill_in "Comment faire", with: "Ouvrir le capot, rincer le filtre."
    click_on "Ajouter la tâche"
    expect(page).to have_content("Tâche « Nettoyer le filtre » ajoutée.")

    go_to_tab("Aujourd'hui")
    expect(page).to have_content(/Nettoyer le filtre\s+Clim de la chambre · aujourd'hui/)
    click_link "Nettoyer le filtre"
    expect(page).to have_content("Ouvrir le capot, rincer le filtre.")
    click_on "Marquer comme fait : Nettoyer le filtre"
    expect(page).to have_content("Nettoyer le filtre noté pour « Clim de la chambre ».")

    go_to_tab("Maison")
    click_on "Équipements"
    click_on "Clim de la chambre"
    click_on "Historique"
    expect(page).to have_content("par vous")
    click_on "Modifier"
    click_on "Supprimer l'équipement"
    within("dialog", text: "Ses tâches et leur historique partent aussi.") { click_on "Supprimer l'équipement" }
    expect(page).to have_content("Équipement « Clim de la chambre » supprimé.")
    expect(page).to have_content("Aucun équipement pour l'instant")
  end
end
