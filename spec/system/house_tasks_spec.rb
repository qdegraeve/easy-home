require "rails_helper"

# Critical journey: a task of the house itself, with how to do it (see docs/tests.md and
# docs/conception/equipements-et-taches.md). Added from the "+" of Maison, it shows up in "Aujourd'hui", opens its
# sheet with the "Comment faire", and is done from there into the journal.
RSpec.describe "House tasks", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "adds a task of the house with its instructions, reads them from Aujourd'hui and does it" do
    create(:user, :with_household, email: "quentin@example.com", password: "secret-password")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    go_to_tab("Maison")
    expect(page).to have_no_link("Tâches de la maison")
    click_on "Ajouter"
    click_on "Une tâche de la maison"
    fill_in "Tâche", with: "Sortir la poubelle jaune"
    fill_in "Date", with: Date.new(2026, 11, 16)
    check "À ne pas rater"
    fill_in "Comment faire", with: "Bac jaune devant le portail.\nCouvercle fermé."
    click_on "Ajouter la tâche"
    expect(page).to have_content("Tâche « Sortir la poubelle jaune » ajoutée.")
    expect(page).to have_css("h1", text: "Tâches de la maison")

    go_to_tab("Aujourd'hui")
    expect(page).to have_content("À faire aujourd'hui · 1")
    click_link "Sortir la poubelle jaune"
    expect(page).to have_css("h1", text: "Sortir la poubelle jaune")
    expect(page).to have_content("Tâche de la maison")
    expect(page).to have_content("Bac jaune devant le portail.")
    expect(page).to have_content("Couvercle fermé.")
    click_on "Marquer comme fait : Sortir la poubelle jaune"
    expect(page).to have_content("Sortir la poubelle jaune noté.")

    go_to_tab("Journal")
    expect(page).to have_content(/Sortir la poubelle jaune\s+par vous · 10 h 00/)
  end

  it "repeats a task every 3 months after the last time: done today, back in 3 months" do
    create(:user, :with_household, email: "quentin@example.com", password: "secret-password")

    visit new_task_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    visit new_task_path
    fill_in "Tâche", with: "Manœuvrer le groupe de sécurité"
    choose "Tous les N jours, semaines, mois ou ans après la dernière fois"
    fill_in "Prochaine fois le", with: Date.new(2026, 11, 16)
    fill_in "Répétition", with: "3"
    select "mois", from: "Unité"
    click_on "Ajouter la tâche"
    expect(page).to have_content("Tous les 3 mois · aujourd'hui")

    go_to_tab("Aujourd'hui")
    click_on "Marquer comme fait : Manœuvrer le groupe de sécurité"
    expect(page).to have_content("Manœuvrer le groupe de sécurité noté.")
    go_to_tab("Maison")
    click_on "Tâches de la maison"
    expect(page).to have_content("Tous les 3 mois · dans 3 mois")

    click_link "Manœuvrer le groupe de sécurité"
    expect(page).to have_css("h1", text: "Manœuvrer le groupe de sécurité")
    click_on "Supprimer la tâche" # from its sheet
    within("dialog", text: "Son historique et ses photos partent aussi.") { click_on "Supprimer la tâche" }
    expect(page).to have_content("Tâche « Manœuvrer le groupe de sécurité » supprimée.")
    expect(page).to have_content("Aucune tâche de la maison pour l'instant.")
    page.go_back # never the deleted task again
    expect(page).to have_css("h1", text: "Tâches de la maison")
  end
end
