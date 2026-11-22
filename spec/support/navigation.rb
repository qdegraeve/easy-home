# Moving around the app in system specs, as a user does: through the tab bar.
module NavigationHelpers
  def go_to_tab(name)
    within("nav[aria-label=Sections]") { click_on name }
  end

  def open_plant(name)
    go_to_tab("Maison")
    click_on "Plantes"
    click_on name
  end

  # Soins / Photos / Historique on the plant page.
  def open_plant_tab(name)
    within("nav[aria-label='Parties de la fiche']") { click_on name }
    expect(page).to have_css("nav[aria-label='Parties de la fiche'] a[aria-current=page]", text: name)
  end
end

RSpec.configure do |config|
  config.include NavigationHelpers, type: :system
end
