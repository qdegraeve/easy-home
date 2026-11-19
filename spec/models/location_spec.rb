require "rails_helper"

RSpec.describe Location, type: :model do
  it "refuse deux emplacements de même nom dans un foyer, sans tenir compte de la casse" do
    location = create(:location, name: "Terrasse")

    expect(build(:location, household: location.household, name: "terrasse")).not_to be_valid
    expect(build(:location, name: "Terrasse")).to be_valid
  end
end
