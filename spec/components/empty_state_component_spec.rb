require "rails_helper"

RSpec.describe EmptyStateComponent, type: :component do
  it "says it in a sentence, with an optional title, icon and action" do
    component = described_class.new(icon: :sprout, title: "Aucune plante", text: "Ajoutez la première.")
    render_inline(component) { "Ajouter" }

    expect(page).to have_css("svg[aria-hidden=true]", visible: :all)
    expect(page).to have_text("Aucune plante")
    expect(page).to have_text("Ajoutez la première.")
    expect(page).to have_text("Ajouter")
  end
end
