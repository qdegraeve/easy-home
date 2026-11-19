require "rails_helper"

RSpec.describe Location, type: :model do
  it "rejects two locations with the same name in a household, case insensitively" do
    location = create(:location, name: "Terrasse")

    expect(build(:location, household: location.household, name: "terrasse")).not_to be_valid
    expect(build(:location, name: "Terrasse")).to be_valid
  end
end
