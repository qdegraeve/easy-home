require "rails_helper"

# In the Android app (Hotwire Native user agent), the native top bar replaces the web header and the "← …" links.
RSpec.describe "Pages in the Android app", type: :request do
  let(:user) { create(:user, :with_household) }
  let(:plant) { create(:plant, :watered, household: user.households.sole, name: "Citronnier") }
  let(:in_app) { { "User-Agent" => "Mozilla/5.0 (Linux; Android 17) Hotwire Native Android; Turbo Native Android" } }

  before { post session_path, params: { email: user.email, password: "password" } }

  it "hides the web header in the app and keeps its links at the bottom of the home page" do
    get root_path, headers: in_app

    page = response.parsed_body
    expect(page.at_css("header")).to be_nil
    account = page.at_css("nav[aria-label=Compte]")
    expect(account.css("a").map { |link| [ link.text, link["href"] ] }).to eq([
      [ "Notifications", edit_notification_settings_path ],
      [ "Mes foyers", households_path ]
    ])
    expect(account.at_css("form[action='#{session_path}']")["data-turbo-confirm"]).to eq("Se déconnecter ?")
  end

  it "keeps the web header, and no account links at the bottom, in the browser" do
    get root_path

    page = response.parsed_body
    expect(page.at_css("header").text).to include("Se déconnecter")
    expect(page.at_css("nav[aria-label=Compte]")).to be_nil
  end

  it "hides the back links in the app only" do
    pages = {
      plant_path(plant) => "← Mes plantes",
      new_plant_path => "← Mes plantes",
      edit_plant_path(plant) => "← Mes plantes",
      new_plant_task_path(plant) => "← Citronnier",
      edit_notification_settings_path => "← Accueil",
      edit_household_path(user.households.sole) => "← Retour"
    }

    pages.each do |path, back_link|
      get path, headers: in_app
      expect(response.body).not_to include(back_link), path

      get path
      expect(response.body).to include(back_link), path
    end
  end

  it "shows the account links on the first household form, the only page of a user without household" do
    other = create(:user)
    post session_path, params: { email: other.email, password: "password" }

    get new_household_path, headers: in_app

    expect(response.parsed_body.at_css("nav[aria-label=Compte]").text).to include("Notifications", "Se déconnecter")
  end
end
