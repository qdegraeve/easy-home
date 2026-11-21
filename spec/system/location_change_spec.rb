require "rails_helper"

# Critical journey: changing a location signals the analyses of its plants to review, and the analysis is restarted
# plant by plant (see docs/tests.md and docs/ux/revue-ux.md, "Changement d'emplacement et analyses").
RSpec.describe "Change of a location", type: :system do
  include ActiveJob::TestHelper

  it "changes the exposure of a location, sees the analysis to review, restarts it, and the signal goes" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    household = user.households.sole
    terrace = create(:location, household:, name: "Terrasse", exposure: :partial_shade, sheltered: true)
    lemon = create(:plant, :watered, household:, name: "Citronnier", location: terrace)
    create(:plant_analysis, :done, plant: lemon, place: lemon.place)

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    go_to_tab("Maison")
    expect(page).to have_no_content("analyse à revoir")
    click_on "Adresse et emplacements"
    click_on "Modifier l'emplacement « Terrasse »"
    expect(page).to have_content("signalera l'analyse de sa plante à revoir")
    find("label", text: "Plein soleil").click
    uncheck "Abrité du vent"
    click_on "Enregistrer"
    expect(page).to have_content("Emplacement « Terrasse » modifié.")

    go_to_tab("Maison")
    expect(page).to have_content("1 analyse à revoir")
    click_on "Plantes"
    expect(page).to have_content("Analyse à revoir : le lieu a changé")
    click_on "Citronnier"
    expect(page).to have_content(
      "Lors de la dernière analyse : mi-ombre, abrité du vent. Maintenant : plein soleil, exposé au vent."
    )

    click_on "Relancer l'analyse"
    expect(page).to have_field(
      "Une question, une remarque ? (facultatif)",
      with: "Lieu changé depuis la dernière analyse : avant mi-ombre, abrité du vent, maintenant plein soleil, " \
            "exposé au vent."
    )

    # While the new analysis runs, the restart is not offered again; once done in the new place, the signal goes.
    click_on "Lancer l'analyse"
    expect(page).to have_content("Analyse en cours")
    expect(page).to have_no_content("Analyse à revoir")
    perform_enqueued_jobs
    expect(page).to have_content("À surveiller")
    expect(page).to have_no_content("Analyse à revoir")
  end
end
