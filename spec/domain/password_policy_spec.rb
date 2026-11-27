require "rails_helper"

RSpec.describe PasswordPolicy do
  subject(:policy) { described_class.new }

  it "accepts a long password, without any composition rule" do
    expect(policy.errors("trois mots au soleil")).to be_empty
    expect(policy.errors("cafe-tortue-volcan")).to be_empty
  end

  it "refuses fewer than 15 characters" do
    expect(policy.errors("Court!Ab1")).to eq([ :too_short ])
  end

  it "refuses what is easy to guess" do
    [
      "passwordpassword", "aaaaaaaaaaaaaaaa", "abcabcabcabcabcabc", "123456789012345", "azertyuiopqsdfgh",
      "qwertyuiopasdfgh", "zyxwvutsrqponmlk", "easyhome2026!!!", "motdepasse12345", "lea.martin.2026"
    ].each do |password|
      expect(policy.errors(password, email: "lea.martin@example.com")).to eq([ :guessable ]), password
    end
  end

  it "accepts symbols or emoji only when varied, and leaves a huge input to has_secure_password" do
    expect(policy.errors("🌴🌋🐢☀️🌊🥥🍍🦎🌺🐚🌈🏝️🦜🐠🌿")).to be_empty
    expect(policy.errors("a" * 100_000)).to be_empty
    expect(User.new(email: "a@example.com", password: "a" * 100_000)).not_to be_valid
  end

  it "accepts the allowed passwords whatever the rules: passwordpassword outside production" do
    expect(described_class.new(allowed: [ "passwordpassword" ]).errors("passwordpassword")).to be_empty
    expect(Rails.configuration.x.allowed_passwords).to eq([ "passwordpassword" ])
  end
end
