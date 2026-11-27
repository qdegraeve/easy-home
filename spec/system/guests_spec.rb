require "rails_helper"

# Critical journey (docs/tests.md, ADR 0019): the neighbour during the holidays. Invited with one plant and the tasks
# of the house opened, for a period, they see and do those tasks only.
RSpec.describe "Guests", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household, name: "Maison") }
  let!(:manager) { create(:household_member, household:, role: :manager, user: create(:user, name: "Quentin")).user }

  around { |example| travel_to(Time.zone.parse("2026-12-20 09:00")) { example.run } }

  it "opens a plant and the house tasks to a guest, who does them and sees nothing else" do
    create(:plant, :watered, household:, name: "Ficus", interval_days: 1, last_watered_at: 1.day.ago)
    create(:plant, :watered, household:, name: "Orchidée", interval_days: 1, last_watered_at: 1.day.ago)
    create(:equipment, household:, name: "Piscine")

    visit new_session_path
    fill_in "Votre adresse e-mail", with: manager.email
    fill_in "Votre mot de passe", with: "passwordpassword"
    click_on "Se connecter"
    click_on "Réglages"
    click_on "Membres du foyer"
    click_on "Inviter quelqu'un"
    fill_in "E-mail", with: "marc@example.com"
    fill_in "Prénom", with: "Marc"
    choose "Invité"
    check "Ficus"
    check "Tâches de la maison"
    fill_in "Du", with: "2026-12-20"
    fill_in "Au", with: "2027-01-05"
    click_on "Envoyer l'invitation"
    expect(page).to have_content("Invitation envoyée à marc@example.com.")
    link = URI(ActionMailer::Base.deliveries.last.text_part.body.to_s[%r{http\S+/invitations/\S+}]).path
    click_on "Réglages"
    click_on "Se déconnecter"
    within("dialog", text: "Se déconnecter ?") { click_on "Se déconnecter" }

    visit link
    expect(page).to have_content("Quentin vous invite comme invité.")
    fill_in "Prénom", with: "Marc"
    fill_in "Mot de passe", with: "passwordpassword"
    fill_in "Confirmation du mot de passe", with: "passwordpassword"
    click_on "Créer mon compte et rejoindre Maison"

    expect(page).to have_content("Bienvenue dans Maison.")
    within("[aria-labelledby=due-today]") do
      expect(page).to have_content("Ficus")
      expect(page).to have_no_content("Orchidée")
    end

    go_to_tab("Maison")
    click_on "Plantes"
    expect(page).to have_link("Ficus")
    expect(page).to have_no_link("Orchidée")
    click_on "Ficus"
    expect(page).to have_no_link("Modifier")
    expect(page).to have_no_link("Ajouter une tâche")

    travel_to(Time.zone.parse("2027-01-06 09:00"))
    go_to_tab("Aujourd'hui")
    expect(page).to have_content("Votre accès à Maison s'est terminé le")
    expect(page).to have_no_content("Ficus")
  end
end
