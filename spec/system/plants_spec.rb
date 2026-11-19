require "rails_helper"

# Parcours critiques : ajout d'une plante, arrosage, archivage (voir docs/tests.md).
RSpec.describe "Plantes", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "ajoute une plante, l'arrose, voit le journal et la prochaine échéance, puis l'archive" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    create(:location, household: user.households.first, name: "Terrasse", exposure: :partial_shade)

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    click_on "+ Ajouter une plante"

    fill_in "Nom", with: "Basilic"
    select "Terrasse", from: "Emplacement"
    fill_in "Arrosage", with: "2"
    fill_in "Dernier arrosage", with: Date.new(2026, 11, 14)
    click_on "Ajouter la plante"

    expect(page).to have_content("Plante « Basilic » ajoutée.")
    expect(page).to have_content("Tous les 2 jours")
    expect(page).to have_content("Prochain arrosage : aujourd'hui")
    expect(page).to have_content("Dernier arrosage : sam 14 nov.")

    click_on "← Mes plantes"
    expect(page).to have_content("À arroser aujourd'hui · 1")
    click_on "Arrosée : Basilic"

    expect(page).to have_content("Arrosage noté pour « Basilic ».")
    expect(page).to have_content("Rien à arroser aujourd'hui.")

    click_on "Basilic"
    expect(page).to have_content("Prochain arrosage : dans 2 j")
    expect(page).to have_content("Dernier arrosage : lun 16 nov.")
    within("section", text: "Journal") do
      expect(page).to have_content("lun 16 nov.")
      expect(page).to have_content("sam 14 nov.")
    end

    accept_confirm { click_on "Archiver" }

    expect(page).to have_content("Plante « Basilic » archivée.")
    expect(page).to have_content("plus de rappel")
    expect(page).to have_no_button("Arrosée : Basilic")

    click_on "← Mes plantes"
    expect(page).to have_content("Aucune plante pour l'instant")
    expect(page).to have_content("Plantes archivées · 1")
  end
end
