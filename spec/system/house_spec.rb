require "rails_helper"

# Critical journey: the address and locations feed the watering advice (see docs/tests.md).
RSpec.describe "My house", type: :system do
  it "picks the address in the suggestions, sees the computed altitude, then manages locations" do
    create(:user, :with_household, email: "quentin@example.com", password: "passwordpassword")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "passwordpassword"
    click_on "Se connecter"
    go_to_tab("Maison")
    click_on "Adresse et emplacements"

    fill_in "Adresse", with: "12 exemples ville"
    click_on "12 Rue des Exemples 97400 Ville-Exemple"
    click_on "Enregistrer"

    expect(page).to have_content("Adresse enregistrée.")
    expect(page).to have_field("Adresse", with: "12 Rue des Exemples 97400 Ville-Exemple")
    expect(page).to have_field("Altitude", with: "320")

    fill_in "Nom", with: "Terrasse"
    find("label", text: "Mi-ombre").click
    check "Abrité du vent"
    click_on "Ajouter"

    expect(page).to have_content("Emplacement « Terrasse » ajouté.")
    expect(page).to have_content("Mi-ombre · abrité du vent", normalize_ws: true)

    lemon = create(:plant, household: Household.sole, location: Location.find_by!(name: "Terrasse"), name: "Citronnier")
    refresh
    click_on "Supprimer l'emplacement « Terrasse »"
    within("dialog", text: "Sa plante restera, sans emplacement.") { click_on "Revenir" }
    expect(page).to have_no_css("dialog[open]")
    expect(page).to have_content("Mi-ombre · abrité du vent", normalize_ws: true)

    click_on "Supprimer l'emplacement « Terrasse »"
    within("dialog", text: "Supprimer l'emplacement « Terrasse » ?") { click_on "Supprimer" }

    expect(page).to have_content("Emplacement « Terrasse » supprimé.")
    expect(page).to have_no_content("Mi-ombre · abrité du vent", normalize_ws: true)
    expect(lemon.reload.location).to be_nil
  end
end
