require "rails_helper"

# Critical journey: in the Android app (Hotwire Native user agent), the web header is hidden; the settings, sign out
# included, open from the native top bar (see docs/tests.md).
RSpec.describe "In the Android app", type: :system do
  before do
    page.driver.add_headers("User-Agent" => "Mozilla/5.0 (Linux; Android 17) Hotwire Native Android")
  end

  it "reaches the notification settings then signs out through the settings, without the web header" do
    create(:user, :with_household, email: "quentin@example.com", password: "secret-password")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    expect(page).to have_css("h1", text: "Aujourd'hui")
    expect(page).to have_no_css("header")

    # The settings button is native (top bar of the app): the page it opens.
    visit settings_path
    click_on "Notifications"
    expect(page).to have_css("h1", text: "Notifications")
    expect(page).to have_no_link("← Accueil")

    visit settings_path
    click_on "Se déconnecter"
    within("dialog", text: "Se déconnecter ?") { click_on "Se déconnecter" }

    expect(page).to have_button("Se connecter")
  end

  # The native side of the bridge components (floating button, "⋮" menu), played by the page: it records what the
  # page sends and answers like the app would.
  FAKE_APP = <<~JS.freeze
    window.appMessages = window.appMessages || []
    window.HotwireNative.web.setAdapter({
      platform: "android",
      supportedComponents: ["button", "menu"],
      supportsComponent(component) { return this.supportedComponents.includes(component) },
      receive(message) { window.appMessages.push(message) }
    })
  JS

  def menu_titles
    page.evaluate_script(<<~JS)
      window.appMessages.filter((message) => message.component == "menu").at(-1).data.items.map((item) => item.title)
    JS
  end

  def choose_in_menu(title)
    page.execute_script(<<~JS)
      const message = window.appMessages.filter((message) => message.component == "menu").at(-1)
      const item = message.data.items.find((item) => item.title == #{title.to_json})
      window.HotwireNative.web.receive({ ...message, data: { selectedIndex: item.index } })
    JS
  end

  it "moves the plant actions to the native menu, kept in step with the page, and asks before acting" do
    page.driver.add_headers("User-Agent" => "Mozilla/5.0 Hotwire Native Android; bridge-components: [button menu]")
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    plant = create(:plant, :watered, household: user.households.sole, name: "Basilic")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    visit plant_path(plant)
    page.execute_script(FAKE_APP)

    expect(page).to have_no_button("Archiver") # shown by the app, not in the page
    expect(menu_titles).to eq([ "Modifier", "Archiver", "Supprimer" ])

    choose_in_menu("Archiver")
    within("dialog", text: "Les rappels s'arrêtent") { click_on "Archiver" }
    expect(page).to have_content("Plante « Basilic » archivée.")
    # The page was refreshed in place: the menu now offers to restore, never the former "Archiver".
    expect(page).to have_css("#plant-actions-archived", visible: :hidden)
    page.document.synchronize { raise Capybara::ExpectationNotMet unless menu_titles.include?("Restaurer") }
    expect(menu_titles).to eq([ "Modifier", "Restaurer", "Supprimer" ])

    choose_in_menu("Supprimer")
    within("dialog", text: "Supprimer définitivement") { click_on "Supprimer" }
    expect(page).to have_content("Plante « Basilic » supprimée.")
  end

  it "shows the native Tâche and Analyse buttons on the care tab, and opens the task form from the first" do
    page.driver.add_headers("User-Agent" => "Mozilla/5.0 Hotwire Native Android; bridge-components: [button menu]")
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    plant = create(:plant, :watered, household: user.households.sole, name: "Basilic")
    create(:photo, plant:)

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    visit plant_path(plant)
    page.execute_script(FAKE_APP)

    expect(page).to have_no_link("Ajouter une tâche") # shown by the app, not in the page
    buttons = page.evaluate_script(<<~JS)
      window.appMessages.filter((message) => message.component == "button").map((message) => message.data)
    JS
    expect(buttons).to contain_exactly(
      include("label" => "Tâche", "order" => 1),
      include("label" => "Analyse", "order" => 2)
    )

    page.execute_script(<<~JS)
      const message = window.appMessages.find((message) => message.data.label == "Tâche")
      window.HotwireNative.web.receive({ ...message, data: {} })
    JS
    expect(page).to have_css("h1", text: "Ajouter une tâche")
  end

  it "moves the date, cover and delete actions of a photo to the native menu, and still asks before deleting" do
    page.driver.add_headers("User-Agent" => "Mozilla/5.0 Hotwire Native Android; bridge-components: [button menu]")
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    plant = create(:plant, :watered, household: user.households.sole, name: "Basilic")
    photo = create(:photo, plant:)

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    visit plant_photo_path(plant, photo)
    page.execute_script(FAKE_APP)

    expect(page).to have_no_button("Supprimer la photo") # shown by the app, not in the page
    expect(menu_titles).to eq([ "Modifier la date", "Utiliser comme photo de couverture", "Supprimer la photo" ])

    choose_in_menu("Utiliser comme photo de couverture")
    expect(page).to have_content("Photo de couverture choisie.")
    visit plant_photo_path(plant, photo)
    page.execute_script(FAKE_APP)
    expect(menu_titles).to eq([ "Modifier la date", "Supprimer la photo" ])

    choose_in_menu("Supprimer la photo")
    within("dialog") { click_on "Supprimer la photo" }
    expect(page).to have_content("Photo supprimée.")
  end
end
