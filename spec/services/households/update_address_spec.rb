require "rails_helper"

RSpec.describe Households::UpdateAddress do
  let(:household) { create(:household) }
  let(:address) { { address: "12 Rue des Exemples", latitude: "-20.9", longitude: "55.45" } }

  def call(params) = described_class.new.call(household:, params:)

  it "saves the address and computes the altitude from the position" do
    expect(call(address)).to be_success

    expect(household.reload).to have_attributes(address: "12 Rue des Exemples", altitude_m: 320)
    expect(household.latitude).to eq(BigDecimal("-20.9"))
  end

  it "keeps a hand-corrected altitude when the position does not change" do
    call(address)

    call(address.merge(altitude_m: "350"))

    expect(household.reload.altitude_m).to eq(350)
  end

  it "recomputes the altitude when the position changes" do
    call(address)
    household.update!(altitude_m: 350)

    call(address.merge(latitude: "-21.0", altitude_m: "350"))

    expect(household.reload.altitude_m).to eq(320)
  end

  it "saves the address without altitude when the service is down" do
    Geo.elevation = FakeElevation.new(result: nil)

    expect(call(address)).to be_success
    expect(household.reload).to have_attributes(altitude_m: nil, address: "12 Rue des Exemples")
  end

  it "clears the position and altitude when the address is emptied" do
    call(address)

    call({ address: "", latitude: "-20.9", longitude: "55.45", altitude_m: "320" })

    expect(household.reload).to have_attributes(address: nil, latitude: nil, longitude: nil, altitude_m: nil)
  end

  it "fails on an invalid altitude" do
    result = call({ address: "12 Rue des Exemples", altitude_m: "99999" })

    expect(result.failure).to match([ :invalid, household ])
    expect(household.reload.address).to be_nil
  end
end
