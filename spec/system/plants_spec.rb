require "rails_helper"

# Parcours critiques : ajout d'une plante, arrosage, correction, archivage (voir docs/tests.md).
RSpec.describe "Plantes", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "ajoute une plante, l'arrose, corrige le journal, change l'intervalle, l'archive puis la restaure" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    create(:location, household: user.households.first, name: "Terrasse", exposure: :partial_shade)

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    click_on "+ Ajouter une plante"

    # Saisie invalide (le navigateur bloque les autres) : l'erreur du serveur s'affiche et les valeurs restent.
    fill_in "Nom", with: "   "
    select "Terrasse", from: "Emplacement"
    fill_in "Arrosage", with: "2"
    fill_in "Dernier arrosage", with: Date.new(2026, 11, 14)
    click_on "Ajouter la plante"
    expect(page).to have_content("Nom doit être rempli(e)")
    expect(page).to have_field("Arrosage", with: "2")

    fill_in "Nom", with: "Basilic"
    click_on "Ajouter la plante"
    expect(page).to have_content("Plante « Basilic » ajoutée.")
    expect(page).to have_content("Tous les 2 jours")
    expect(page).to have_content("Prochain arrosage : aujourd'hui")
    expect(page).to have_content("Dernier arrosage : sam 14 nov.")

    # Arrosage depuis l'accueil, une seule fois par jour.
    click_on "← Mes plantes"
    expect(page).to have_content("À faire aujourd'hui · 1")
    click_on "Arrosée : Basilic"
    expect(page).to have_content("Arrosage noté pour « Basilic ».")
    expect(page).to have_content("Rien à faire aujourd'hui.")

    click_on "Basilic"
    expect(page).to have_content("Prochain arrosage : dans 2 j")
    expect(page).to have_content("Arrosée aujourd'hui")
    expect(page).to have_no_button("Arrosée : Basilic")

    # Correction : l'arrosage du jour était une erreur.
    click_on "Annuler l'arrosage du lun 16 nov."
    within("dialog", text: "Le prochain arrosage sera recalculé.") { click_on "Oui, confirmer" }
    expect(page).to have_content("Arrosage annulé, prochaine échéance recalculée.")
    expect(page).to have_content("Prochain arrosage : aujourd'hui")
    expect(page).to have_content("Dernier arrosage : sam 14 nov.")
    expect(page).to have_button("Arrosée : Basilic")

    # Nouvel intervalle : l'échéance se recale depuis le dernier arrosage (14 nov. + 5 j).
    click_on "Modifier"
    fill_in "Arrosage", with: "5"
    click_on "Enregistrer"
    expect(page).to have_content("Plante enregistrée.")
    expect(page).to have_content("Tous les 5 jours")
    expect(page).to have_content("Prochain arrosage : dans 3 j")

    # Archivage : plus de rappel, le journal reste.
    click_on "Archiver"
    within("dialog") { click_on "Non, revenir" }
    expect(page).to have_no_css("dialog[open]")
    expect(page).to have_no_content("Plante « Basilic » archivée.")
    click_on "Archiver"
    within("dialog", text: "Les rappels s'arrêtent") { click_on "Oui, confirmer" }
    expect(page).to have_content("Plante « Basilic » archivée.")
    expect(page).to have_content("plus de rappel")
    expect(page).to have_no_button("Arrosée : Basilic")
    click_on "← Mes plantes"
    expect(page).to have_content("Plantes archivées · 1")

    # Restauration quelques jours plus tard : l'arrosage reprend, en retard.
    travel 7.days
    find("summary", text: "Plantes archivées · 1").click
    click_on "Basilic"
    click_on "Restaurer"
    expect(page).to have_content("Plante « Basilic » restaurée.")
    expect(page).to have_content("Prochain arrosage : en retard de 4 j")
    expect(page).to have_button("Arrosée : Basilic")
  end
end
