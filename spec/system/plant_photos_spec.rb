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
    expect(page).to have_button("Prendre ou choisir une photo")
    attach_file "Photo", picture("plant_with_gps.jpg")
    expect(page).to have_content("plant_with_gps.jpg") # the name of the chosen file, next to the button
    click_on "Ajouter la plante"
    expect(page).to have_content("Plante « Citronnier » ajoutée.")
    # Dated from its EXIF shooting date, not from the upload.
    open_plant_tab("Photos")
    expect(page).to have_css("img[alt='Photo du mar 10 nov.']")

    attach_file "Nouvelle photo", picture("not_an_image.jpg") # sent once chosen
    expect(page).to have_content("Photo n'est pas une image JPEG, PNG ou WebP lisible")

    travel 2.days
    attach_file "Nouvelle photo", picture("plant.png") # sent once chosen
    expect(page).to have_content("Photo ajoutée.")
    # A gallery: grouped by month, the date in the alternative text only.
    within("section[aria-labelledby=photos]") do
      expect(page).to have_content("2 photos")
      expect(page).to have_css("h3", text: "novembre 2026")
    end

    find("img[alt='Photo du mar 10 nov.']").click
    expect(page).to have_content("Photo du 10 novembre 2026")
    expect(page).to have_content("1 / 2")
    click_on "Modifier la date" # a dialog of the page, on the photo shown
    within("dialog[open]") do
      fill_in "Date de la photo", with: Date.new(2026, 11, 8)
      click_on "Enregistrer la date"
    end
    expect(page).to have_content("Date de la photo enregistrée.")
    expect(page).to have_content("Photo du 8 novembre 2026")
    # The face of the plant: chosen among its photos.
    click_on "Utiliser comme photo de couverture"
    expect(page).to have_content("Photo de couverture choisie.")
    expect(page).to have_content("Photo du 8 novembre 2026") # still in the viewer
    # Marked in the gallery, and the header shows it now, instead of the latest photo (18 November).
    click_on "← Citronnier"
    within("li", text: "Couverture") { expect(page).to have_css("img[alt='Photo du dim 8 nov.']") }
    find("img[alt='Photo de Citronnier']").click
    expect(page).to have_content("Photo du 8 novembre 2026")
    expect(page).to have_content("Photo de couverture")
    expect(page).to have_no_button("Utiliser comme photo de couverture")

    # From one photo to the other, to follow the growth, in the same page: with the arrows, or the arrow keys. The
    # actions and the address follow the photo shown.
    click_on "Plus récente"
    expect(page).to have_content("Photo du 18 novembre 2026")
    expect(page).to have_content("2 / 2")
    expect(page).to have_no_link("Plus récente")
    expect(page).to have_no_content("Photo de couverture")
    expect(page).to have_button("Utiliser comme photo de couverture")
    refresh
    expect(page).to have_content("Photo du 18 novembre 2026")
    find("body").send_keys(:left)
    expect(page).to have_content("Photo du 8 novembre 2026")
    expect(page).to have_content("1 / 2")
    expect(page).to have_content("Photo de couverture")
    expect(page).to have_no_button("Utiliser comme photo de couverture")

    # Deleted: on to the next photo, as in a gallery.
    click_on "Supprimer la photo"
    expect(page).to have_css("dialog[open] button[data-tone=danger]", text: "Supprimer la photo")
    within("dialog") { click_on "Supprimer la photo" }
    expect(page).to have_content("Photo supprimée.")
    expect(page).to have_content("Photo du 18 novembre 2026")
    expect(page).to have_content("1 / 1")
    # The deleted photo replaced in the history: "back" leaves the viewer.
    page.go_back
    expect(page).to have_css("section[aria-labelledby=photos]") # the gallery, where the viewer was opened from
    expect(page).to have_no_content("Photo du 8 novembre 2026")
    expect(page).to have_no_css("img[alt='Photo du dim 8 nov.']")
  end
end
