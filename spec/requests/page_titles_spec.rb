require "rails_helper"

# The Hotwire Native shell shows the page <title> in its top bar: each page names itself, like its heading.
RSpec.describe "Page titles", type: :request do
  def title_and_heading
    page = response.parsed_body
    [ page.at_css("title").text.strip, page.at_css("h1").text.strip ]
  end

  it "titles the sign in page" do
    get new_session_path

    expect(title_and_heading).to eq([ "Connexion", "Connexion" ])
  end

  it "titles every page of a signed in user like its heading" do
    user = create(:user, :with_household)
    plant = create(:plant, :watered, household: user.households.sole, name: "Citronnier")
    post session_path, params: { email: user.email, password: "password" }

    {
      root_path => "Mes plantes",
      plant_path(plant) => "Citronnier",
      new_plant_path => "Ajouter une plante",
      edit_household_path(user.households.sole) => "Ma maison",
      edit_notification_settings_path => "Notifications"
    }.each do |path, title|
      get path

      expect(title_and_heading).to eq([ title, title ]), path
    end
  end
end
