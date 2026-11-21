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
end

RSpec.configure do |config|
  config.include NavigationHelpers, type: :system
end
