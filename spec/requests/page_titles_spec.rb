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
    photo = create(:photo, plant:, taken_at: Time.zone.parse("2026-11-08 10:00"))
    pruning = create(:task, household: plant.household, subject: plant, title: "Tailler", template_key: nil,
                            recurrence_type: :once, recurrence_config: { "due_on" => "2026-12-01" })
    post session_path, params: { email: user.email, password: "password" }

    {
      root_path => "Aujourd'hui",
      house_path => "Maison",
      plants_path => "Plantes",
      journal_path => "Journal",
      settings_path => "Réglages",
      plant_path(plant) => "Citronnier",
      new_plant_path => "Ajouter une plante",
      edit_household_path(user.households.sole) => "Ma maison",
      edit_notification_settings_path => "Notifications",
      edit_plant_photo_path(plant, photo) => "Date de la photo",
      edit_plant_task_path(plant, pruning) => "Modifier « Tailler »"
    }.each do |path, title|
      get path

      expect(title_and_heading).to eq([ title, title ]), path
    end

    # The photo viewer scrolls through the photos in the same page: the native top bar keeps the plant, the heading
    # follows the photo shown.
    get plant_photo_path(plant, photo)
    expect(title_and_heading).to eq([ "Photos de Citronnier", "Photo du 8 novembre 2026" ])
  end
end
