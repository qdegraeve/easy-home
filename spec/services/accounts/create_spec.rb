require "rails_helper"

RSpec.describe Accounts::Create do
  subject(:result) { described_class.new.call(email_address:, password: "secret-password", household_name:) }

  let(:email_address) { "moi@example.com" }
  let(:household_name) { "Ma maison" }

  it "crée l'utilisateur, son foyer, et l'en rend propriétaire" do
    expect(result).to be_success

    user = result.value!
    expect(user.households.map(&:name)).to eq([ "Ma maison" ])
    expect(user.memberships.sole).to be_owner
  end

  context "avec une adresse e-mail invalide" do
    let(:email_address) { "pas-un-email" }

    it "échoue sans rien créer" do
      expect { result }.not_to change { [ User.count, Household.count, Membership.count ] }
      expect(result.failure).to match([ :invalid, an_instance_of(User) ])
    end
  end

  context "sans nom de foyer" do
    let(:household_name) { "" }

    it "échoue sans créer l'utilisateur" do
      expect { result }.not_to change { [ User.count, Household.count, Membership.count ] }
      expect(result.failure).to match([ :invalid, an_instance_of(Household) ])
    end
  end
end
