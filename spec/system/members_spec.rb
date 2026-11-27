require "rails_helper"

# Critical journey (docs/tests.md, ADR 0019): a manager shares the management, then removes a member, who loses the
# household; the journal keeps who did what.
RSpec.describe "Members", type: :system do
  let(:household) { create(:household, name: "Maison") }
  let!(:manager) { create(:household_member, household:, role: :manager, user: create(:user, name: "Quentin")).user }
  let!(:lea) { create(:household_member, household:, role: :member, user: create(:user, name: "Léa")).user }

  it "names a second manager, removes a member, and keeps her name in the journal" do
    task = create(:task, household:, title: "Sortir la poubelle jaune", template_key: nil)
    task.occurrences.create!(due_at: Time.current, status: :done, completed_at: Time.current, completed_by: lea)

    visit new_session_path
    fill_in "Votre adresse e-mail", with: manager.email
    fill_in "Votre mot de passe", with: "password"
    click_on "Se connecter"
    expect(page).to have_css("h1", text: "Aujourd'hui")

    go_to_tab("Journal")
    expect(page).to have_content("par Léa")

    click_on "Réglages"
    click_on "Membres du foyer"
    click_on "Gérer Léa"
    choose "Gestionnaire"
    click_on "Enregistrer le rôle"
    expect(page).to have_content("Rôle de Léa enregistré.")
    expect(page).to have_content("Gestionnaire · #{lea.email}")

    click_on "Gérer Léa"
    click_on "Retirer du foyer"
    within("dialog", text: "Retirer Léa de Maison ?") { click_on "Retirer du foyer" }
    expect(page).to have_content("Léa ne fait plus partie du foyer.")
    expect(page).to have_no_link("Gérer Léa")

    go_to_tab("Journal")
    expect(page).to have_content("par Léa")
  end
end
