require "rails_helper"

RSpec.describe Invitation do
  include ActiveSupport::Testing::TimeHelpers

  it "stores the digest of its token only, and finds itself by the token while usable" do
    invitation = create(:invitation)

    expect(invitation.token_digest).to eq(Digest::SHA256.hexdigest(invitation.token))
    expect(invitation.token_digest).not_to include(invitation.token)
    expect(described_class.find_usable(invitation.token)).to eq(invitation)
    expect(described_class.find_usable("autre")).to be_nil
    expect(described_class.find_usable(nil)).to be_nil
  end

  it "stops working once accepted, expired, or renewed" do
    accepted = create(:invitation).tap { _1.update!(accepted_at: Time.current) }
    expect(described_class.find_usable(accepted.token)).to be_nil

    expired = create(:invitation)
    travel 7.days + 1.minute do
      expect(described_class.find_usable(expired.token)).to be_nil
    end

    renewed = create(:invitation)
    old_token = renewed.token
    renewed.renew_token.save!
    expect(described_class.find_usable(old_token)).to be_nil
    expect(described_class.find_usable(renewed.token)).to eq(renewed)
  end
end
