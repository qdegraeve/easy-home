require "rails_helper"

RSpec.describe Households::Create do
  let(:user) { create(:user) }

  it "creates the household and makes the user its owner" do
    result = described_class.new.call(user:, params: { name: "Ma maison" })

    expect(result).to be_success
    expect(user.households.sole.name).to eq("Ma maison")
    expect(user.household_members.sole).to be_owner
  end

  it "fails without creating anything when the name is blank" do
    result = nil

    expect { result = described_class.new.call(user:, params: { name: "" }) }
      .not_to change { [ Household.count, HouseholdMember.count ] }
    expect(result.failure).to match([ :invalid, an_instance_of(Household) ])
  end
end
