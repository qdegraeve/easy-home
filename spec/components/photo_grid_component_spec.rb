require "rails_helper"

RSpec.describe PhotoGridComponent, type: :component do
  it "groups the photos by month, newest first, and marks the cover photo only" do
    plant = create(:plant)
    october = create(:photo, plant:, taken_at: Time.zone.parse("2026-10-30 09:00"))
    november = create(:photo, plant:, taken_at: Time.zone.parse("2026-11-02 09:00"))
    plant.update!(cover_photo: october)

    render_inline(described_class.new(plant:, photos: plant.photos.with_attached_image))

    expect(page.all("h3").map(&:text)).to eq([ "novembre 2026", "octobre 2026" ])
    expect(page).to have_css("a[href='/plants/#{plant.id}/photos/#{november.id}'] img[alt='Photo du lun 2 nov.']")
    expect(page).to have_css("li", text: "Couverture", count: 1)
    expect(page.find("li", text: "Couverture")).to have_css("img[alt='Photo du ven 30 oct.']")
  end
end
