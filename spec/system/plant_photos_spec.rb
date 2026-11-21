require "rails_helper"

# Critical journey: photo follow-up of a plant (see docs/tests.md).
RSpec.describe "Plant photos", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  # The browser runs in its own directory: it needs absolute paths.
  def picture(name)
    file_fixture(name).expand_path.to_s
  end

  it "adds a plant with a photo, adds another one, rejects a non picture, redates and deletes a photo" do
    create(:user, :with_household, email: "quentin@example.com", password: "secret-password")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    click_on "Ajouter une plante"
    fill_in "Nom", with: "Citronnier"
    fill_in "Arrosage", with: "3"
    attach_file "Photo", picture("plant_with_gps.jpg")
    click_on "Ajouter la plante"
    expect(page).to have_content("Plante « Citronnier » ajoutée.")
    # Dated from its EXIF shooting date, not from the upload.
    open_plant_tab("Photos")
    expect(page).to have_css("img[alt='Photo du mar 10 nov.']")

    attach_file "Nouvelle photo", picture("not_an_image.jpg")
    click_on "Ajouter la photo"
    expect(page).to have_content("Photo n'est pas une image JPEG, PNG ou WebP lisible")

    travel 2.days
    attach_file "Nouvelle photo", picture("plant.png")
    click_on "Ajouter la photo"
    expect(page).to have_content("Photo ajoutée.")
    expect(page).to have_css("img[alt='Photo du mer 18 nov.']")

    find("img[alt='Photo du mar 10 nov.']").click
    expect(page).to have_content("Photo du 10 novembre 2026")
    fill_in "Date de la photo", with: Date.new(2026, 11, 8)
    click_on "Enregistrer la date"
    expect(page).to have_content("Date de la photo enregistrée.")
    expect(page).to have_content("Photo du 8 novembre 2026")
    click_on "Supprimer la photo"
    expect(page).to have_css("dialog[open] button[data-tone=danger]", text: "Supprimer la photo")
    within("dialog") { click_on "Supprimer la photo" }
    expect(page).to have_content("Photo supprimée.")
    expect(page).to have_no_css("img[alt='Photo du dim 8 nov.']")
    expect(page).to have_css("img[alt='Photo du mer 18 nov.']")
  end
end
