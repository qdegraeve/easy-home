require "rails_helper"

# Critical journey: a task done when needed (see docs/tests.md and docs/conception/equipements-et-taches.md): the salt
# of the dishwasher, never in "Aujourd'hui", done from the page of its equipment with the last time shown, undone
# from the journal, then turned into a monthly task that gets a due date.
RSpec.describe "Tasks done when needed", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "adds the salt when needed, does it from the dishwasher, undoes it, then makes it monthly" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    dishwasher = create(:equipment, household: user.households.sole, kind: "dishwasher", name: "Lave-vaisselle")

    visit equipment_path(dishwasher)
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    visit equipment_path(dishwasher)
    click_on "Ajouter une tâche"
    fill_in "Tâche", with: "Remettre du sel"
    choose "Quand il le faut : pas de date, je note quand je le fais"
    click_on "Ajouter la tâche"
    expect(page).to have_content(/Remettre du sel\s+Quand il le faut · jamais fait/)

    go_to_tab("Aujourd'hui")
    expect(page).to have_no_content("Remettre du sel")

    visit equipment_path(dishwasher)
    click_on "Marquer comme fait : Remettre du sel"
    expect(page).to have_content("Remettre du sel noté pour « Lave-vaisselle ».")
    expect(page).to have_content("dernière fois : lun 16 nov.")

    go_to_tab("Journal")
    click_on "Annuler « Remettre du sel · Lave-vaisselle » du lun 16 nov."
    within("dialog", text: "du journal ?") { click_on "Retirer" }
    expect(page).to have_content("Remettre du sel annulé")

    visit equipment_path(dishwasher)
    click_link "Remettre du sel"
    click_on "Modifier"
    choose "Tous les N jours, semaines, mois ou ans après la dernière fois"
    fill_in "Prochaine fois le", with: Date.new(2026, 12, 1)
    fill_in "Répétition", with: "1"
    select "mois", from: "Unité"
    click_on "Enregistrer"
    expect(page).to have_content("Prochaine fois : dans 15 j")
  end
end
