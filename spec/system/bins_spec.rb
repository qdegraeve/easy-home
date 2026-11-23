require "rails_helper"

# Critical journey: the yellow bin, every other Tuesday, that must not be missed (see docs/tests.md and
# docs/conception/equipements-et-taches.md). Added from its suggestion, done on its day, its next date comes two weeks
# later; forgotten, it is missed in the journal and the next collection opens, never caught up.
RSpec.describe "Bins", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-30 18:00")) { example.run } }

  it "adds the yellow bin from its suggestion, does it, then misses the next one" do
    create(:user, :with_household, email: "quentin@example.com", password: "secret-password")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    go_to_tab("Maison")
    click_on "Ajouter"
    click_on "Une tâche de la maison"
    click_on "Sortir la poubelle jaune"
    expect(page).to have_field("Tâche", with: "Sortir la poubelle jaune")
    expect(page).to have_checked_field("À jour fixe : toutes les N semaines ou chaque année")
    expect(page).to have_checked_field("À ne pas rater")
    fill_in "Prochaine fois le", with: Date.new(2026, 11, 30)
    click_on "Ajouter la tâche"
    expect(page).to have_content("Toutes les 2 semaines, le lundi · aujourd'hui")

    # Done on its evening: the next one two weeks later, the suggestion no longer offered.
    go_to_tab("Aujourd'hui")
    click_on "Marquer comme fait : Sortir la poubelle jaune"
    expect(page).to have_content("Sortir la poubelle jaune noté.")
    go_to_tab("Maison")
    click_on "Tâches de la maison"
    expect(page).to have_content("Toutes les 2 semaines, le lundi · dans 14 j")
    click_on "Ajouter une tâche"
    expect(page).to have_link("Sortir la poubelle grise")
    expect(page).to have_no_link("Sortir la poubelle jaune")

    # Forgotten two weeks later: missed in the journal, the next collection open.
    travel_to(Time.zone.parse("2026-12-15 02:00"))
    Tasks::MarkMissed.new.call
    go_to_tab("Journal")
    expect(page).to have_content("Non fait, prévu le lun 14 déc.")
    go_to_tab("Maison")
    click_on "Tâches de la maison"
    expect(page).to have_content("Toutes les 2 semaines, le lundi · dans 13 j")
  end
end
