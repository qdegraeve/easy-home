require "rails_helper"

RSpec.describe EmptyStateComponent, type: :component do
  it "says it in a sentence, with an optional title, icon and action" do
    render_inline(described_class.new(icon: :sprout, title: "Aucune plante", text: "Ajoutez la première.")) { "Ajouter" }

    expect(page).to have_css("svg[aria-hidden=true]", visible: :all)
    expect(page).to have_text("Aucune plante")
    expect(page).to have_text("Ajoutez la première.")
    expect(page).to have_text("Ajouter")
  end
end
