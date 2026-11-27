require "rails_helper"

# Critical journey: the upkeep suggested for a new equipment (see docs/tests.md and
# docs/conception/equipements-et-taches.md, "Ajouter un équipement"). A dishwasher added, its suggested tasks offered
# unchecked with their first date, two of them checked and added with how to do them, nothing due on Aujourd'hui.
RSpec.describe "Equipment suggestions", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-23 10:00")) { example.run } }

  it "adds a dishwasher, then the filter and the salt among its suggested tasks" do
    create(:user, :with_household, email: "quentin@example.com", password: "passwordpassword")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "passwordpassword"
    click_on "Se connecter"

    go_to_tab("Maison")
    click_on "Ajouter"
    click_on "Un équipement"
    find("label", text: "Lave-vaisselle").click
    click_on "Ajouter l'équipement"

    expect(page).to have_css("h1", text: "Ajouter des tâches d'entretien ?")
    expect(page).to have_content(/Nettoyer le filtre\s+Tous les mois · 1re fois le mer 23 déc\./)
    expect(page).to have_no_checked_field
    check "Nettoyer le filtre"
    check "Remettre du sel"
    click_on "Ajouter les tâches cochées"

    expect(page).to have_content("2 tâches d'entretien ajoutées.")
    expect(page).to have_css("h1", text: "Lave-vaisselle")
    expect(page).to have_content(/Nettoyer le filtre\s+Tous les mois/)
    expect(page).to have_no_content("liquide de rinçage")
    click_link "Nettoyer le filtre"
    expect(page).to have_content("dévisser le filtre d'un quart de tour")
    page.go_back
    click_link "Remettre du sel"
    expect(page).to have_content("Quand le voyant sel s'allume")

    go_to_tab("Aujourd'hui")
    expect(page).to have_content("Tout est à jour")
    expect(page).to have_no_content("Remettre du sel")
  end
end
