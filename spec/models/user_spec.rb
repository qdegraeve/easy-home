require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  it { is_expected.not_to allow_value("pas-un-email").for(:email) }

  it "normalise l'adresse e-mail" do
    expect(build(:user, email: "  Moi@Example.COM ").email).to eq("moi@example.com")
  end
end
