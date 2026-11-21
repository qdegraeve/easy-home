require "rails_helper"

# In the Android app (Hotwire Native user agent), the native top bar replaces the web header and the "← …" links.
RSpec.describe "Pages in the Android app", type: :request do
  let(:user) { create(:user, :with_household) }
  let(:plant) { create(:plant, :watered, household: user.households.sole, name: "Citronnier") }
  let(:in_app) { { "User-Agent" => "Mozilla/5.0 (Linux; Android 17) Hotwire Native Android; Turbo Native Android" } }

  before { post session_path, params: { email: user.email, password: "password" } }

  it "hides the web header in the app, the settings being reached from the home page" do
    get root_path, headers: in_app

    page = response.parsed_body
    expect(page.at_css("header")).to be_nil
    expect(page.at_css("main a[aria-label='Réglages']")["href"]).to eq(settings_path)
  end

  it "keeps the web header, with the settings, in the browser" do
    get root_path

    page = response.parsed_body
    expect(page.at_css("header a[aria-label='Réglages']")["href"]).to eq(settings_path)
    expect(page.at_css("main a[aria-label='Réglages']")).to be_nil
  end

  it "hides the back links in the app only" do
    pages = {
      plant_path(plant) => "← Plantes",
      new_plant_path => "← Plantes",
      edit_plant_path(plant) => "← Citronnier",
      plants_path => "← Maison",
      new_plant_task_path(plant) => "← Citronnier",
      edit_notification_settings_path => "← Réglages",
      edit_household_path(user.households.sole) => "← Maison"
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

  it "leaves the tabs to the app, which has native ones, and keeps the web tab bar in the browser" do
    get plant_path(plant), headers: in_app
    expect(response.parsed_body.at_css("nav[aria-label=Sections]")).to be_nil

    get plant_path(plant)
    expect(response.parsed_body.at_css("nav[aria-label=Sections]")).to be_present
  end

  it "deletes a plant in place of its page, so that \"back\" never shows it again in the app" do
    get plant_path(plant), headers: in_app
    delete_form = response.parsed_body.at_css("form[action='#{plant_path(plant)}'][data-turbo-confirm]")
    expect(delete_form["data-turbo-action"]).to eq("replace")

    delete plant_path(plant), headers: in_app
    expect(response).to redirect_to(plants_path)
  end
end
