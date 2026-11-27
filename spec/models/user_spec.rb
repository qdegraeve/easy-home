require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  it { is_expected.not_to allow_value("pas-un-email").for(:email) }
  it { is_expected.to validate_length_of(:name).is_at_most(50) }
  it { is_expected.to validate_length_of(:password).is_at_least(15) }

  it "normalizes the email" do
    expect(build(:user, email: "  Moi@Example.COM ").email).to eq("moi@example.com")
  end

  describe "#display_name" do
    it "is the first name, squished, else the start of the email" do
      expect(build(:user, name: "  Léa  ").display_name).to eq("Léa")
      expect(build(:user, name: "   ", email: "lea.martin@example.com").display_name).to eq("Lea")
    end
  end
end
