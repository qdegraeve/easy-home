require "rails_helper"

RSpec.describe Households::UpdateAddress do
  let(:household) { create(:household) }
  let(:address) { { address: "12 Rue des Exemples", latitude: "-20.9", longitude: "55.45" } }

  def call(params) = described_class.new.call(household:, params:)

  it "enregistre l'adresse et calcule l'altitude depuis la position" do
    expect(call(address)).to be_success

    expect(household.reload).to have_attributes(address: "12 Rue des Exemples", altitude_m: 320)
    expect(household.latitude).to eq(BigDecimal("-20.9"))
  end

  it "garde l'altitude corrigée à la main quand la position ne change pas" do
    call(address)

    call(address.merge(altitude_m: "350"))

    expect(household.reload.altitude_m).to eq(350)
  end

  it "recalcule l'altitude quand la position change" do
    call(address)
    household.update!(altitude_m: 350)

    call(address.merge(latitude: "-21.0", altitude_m: "350"))

    expect(household.reload.altitude_m).to eq(320)
  end

  it "enregistre l'adresse sans altitude quand le service ne répond pas" do
    Geo.elevation = FakeElevation.new(result: nil)

    expect(call(address)).to be_success
    expect(household.reload).to have_attributes(altitude_m: nil, address: "12 Rue des Exemples")
  end

  it "efface la position et l'altitude quand l'adresse est vidée" do
    call(address)

    call({ address: "", latitude: "-20.9", longitude: "55.45", altitude_m: "320" })

    expect(household.reload).to have_attributes(address: nil, latitude: nil, longitude: nil, altitude_m: nil)
  end

  it "échoue sur une altitude invalide" do
    result = call({ address: "12 Rue des Exemples", altitude_m: "99999" })

    expect(result.failure).to match([ :invalid, household ])
    expect(household.reload.address).to be_nil
  end
end
