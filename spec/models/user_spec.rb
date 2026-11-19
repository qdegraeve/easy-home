require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
  it { is_expected.not_to allow_value("pas-un-email").for(:email_address) }

  it "normalise l'adresse e-mail" do
    expect(build(:user, email_address: "  Moi@Example.COM ").email_address).to eq("moi@example.com")
  end
end
