require "rails_helper"

RSpec.describe Households::Create do
  let(:user) { create(:user) }

  it "crée le foyer et en rend l'utilisateur propriétaire" do
    result = described_class.new.call(user:, params: { name: "Ma maison" })

    expect(result).to be_success
    expect(user.households.sole.name).to eq("Ma maison")
    expect(user.household_members.sole).to be_owner
  end

  it "échoue sans rien créer quand le nom est vide" do
    result = nil

    expect { result = described_class.new.call(user:, params: { name: "" }) }
      .not_to change { [ Household.count, HouseholdMember.count ] }
    expect(result.failure).to match([ :invalid, an_instance_of(Household) ])
  end
end
