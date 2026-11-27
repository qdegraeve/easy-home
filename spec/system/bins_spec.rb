require "rails_helper"

# Critical journey: the yellow bin, every other Tuesday, that must not be missed (see docs/tests.md and
# docs/conception/equipements-et-taches.md). Added from its suggestion, done on its day, its next date comes two weeks
# later; forgotten, it is missed in the journal and the next collection opens, never caught up.
RSpec.describe "Bins", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-12-01 18:00")) { example.run } }

  it "adds the yellow bin from its suggestion, does it, then misses the next one" do
    create(:user, :with_household, email: "quentin@example.com", password: "passwordpassword")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "passwordpassword"
    click_on "Se connecter"

    go_to_tab("Maison")
    click_on "Ajouter"
    click_on "Une tâche de la maison"
    click_on "Sortir la poubelle jaune"
    expect(page).to have_field("Tâche", with: "Sortir la poubelle jaune")
    expect(page).to have_checked_field("À jour fixe : toutes les N semaines ou chaque année")
    expect(page).to have_checked_field("À ne pas rater")
    expect(page).to have_select("Rappel le jour même", selected: "19:00")
    expect(page).to have_content("La veille de la collecte, une semaine sur deux.")
    fill_in "Prochaine fois le", with: Date.new(2026, 12, 1)
    click_on "Ajouter la tâche"
    expect(page).to have_content("Toutes les 2 semaines, le mardi · aujourd'hui")

    # Done on its evening: the next one two weeks later, the suggestion no longer offered.
    go_to_tab("Aujourd'hui")
    expect(page).to have_content("ce soir 19 h · aujourd'hui")
    click_on "Marquer comme fait : Sortir la poubelle jaune"
    expect(page).to have_content("Sortir la poubelle jaune noté.")
    go_to_tab("Maison")
    click_on "Tâches de la maison"
    expect(page).to have_content("Toutes les 2 semaines, le mardi · dans 14 j")
    click_on "Ajouter une tâche"
    expect(page).to have_link("Sortir la poubelle grise")
    expect(page).to have_no_link("Sortir la poubelle jaune")

    # Forgotten two weeks later: missed in the journal, the next collection open.
    travel_to(Time.zone.parse("2026-12-16 02:00"))
    Tasks::MarkMissed.new.call
    go_to_tab("Journal")
    expect(page).to have_content("Non fait, prévu le mar 15 déc.")
    go_to_tab("Maison")
    click_on "Tâches de la maison"
    expect(page).to have_content("Toutes les 2 semaines, le mardi · dans 13 j")
  end

  it "keeps a forgotten flexible yearly task to do, then brings it back on its day the next year" do
    create(:user, :with_household, email: "quentin@example.com", password: "passwordpassword")

    visit new_task_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "passwordpassword"
    click_on "Se connecter"
    visit new_task_path
    fill_in "Tâche", with: "Préparer la saison cyclonique"
    choose "À jour fixe : toutes les N semaines ou chaque année"
    fill_in "Prochaine fois le", with: Date.new(2026, 12, 3)
    fill_in "Répétition", with: "1"
    select "ans", from: "Unité"
    click_on "Ajouter la tâche"
    expect(page).to have_content("Chaque année, le 3 décembre · dans 2 j")

    # Forgotten past its 3 days of tolerance: missed once, still to do; done, back on December 3rd.
    travel_to(Time.zone.parse("2026-12-08 02:00"))
    Tasks::MarkMissed.new.call
    go_to_tab("Aujourd'hui")
    click_on "Marquer comme fait : Préparer la saison cyclonique"
    expect(page).to have_content("Préparer la saison cyclonique noté.")
    go_to_tab("Maison")
    click_on "Tâches de la maison"
    expect(page).to have_content("Chaque année, le 3 décembre · dans 12 mois")
    go_to_tab("Journal")
    expect(page).to have_content("Non fait, prévu le jeu 3 déc.")
  end
end
