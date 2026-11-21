require "rails_helper"

RSpec.describe ListGroupComponent, type: :component do
  it "names the section by its heading and lists the rows" do
    render_inline(described_class.new(title: "Journal", id: "journal", icon: :history)) do |group|
      group.with_row { "Arrosée" }
      group.with_row { "Tailler" }
      "Rien pour l'instant"
    end

    expect(page).to have_css("section[aria-labelledby=journal] h2#journal", text: "Journal")
    expect(page.all("li").map(&:text)).to eq([ "Arrosée", "Tailler" ])
    expect(page).to have_no_text("Rien pour l'instant")
  end

  it "shows the block content when there is no row" do
    render_inline(described_class.new(title: "Journal", id: "journal")) { "Rien pour l'instant" }

    expect(page).to have_no_css("ul")
    expect(page).to have_text("Rien pour l'instant")
  end
end
