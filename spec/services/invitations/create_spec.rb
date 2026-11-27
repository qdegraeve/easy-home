require "rails_helper"

RSpec.describe Invitations::Create do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household, name: "Maison") }
  let(:manager) { create(:household_member, household:, role: :manager, user: create(:user, name: "Quentin")).user }

  def invite(params = {}, access = {})
    described_class.new.call(household:, created_by: manager, params: { role: "member", **params }, access:)
  end

  it "reserves a place, and e-mails right away (no job) a link valid 7 days to the address given" do
    travel_to(Time.zone.parse("2026-11-27 10:00")) do
      invitation = invite(role: "manager", invitee_name: " Léa ", email: " Lea@Example.COM ").value!

      expect(invitation.household_member).to have_attributes(user: nil, role: "manager", invitee_name: "Léa")
      expect(invitation).to have_attributes(email: "lea@example.com", expires_at: Time.zone.parse("2026-12-04 10:00"))
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "lea@example.com" ])
      expect(mail.subject).to eq("Invitation à rejoindre Maison sur Easy Home")
      expect(mail.text_part.body.to_s).to include("Quentin vous invite", "/invitations/#{invitation.token}")
      expect(Invitation.where(token_digest: invitation.token)).to be_empty
    end
  end

  it "refuses an unknown role, a missing or invalid e-mail, someone already in the household, reserving nothing" do
    create(:household_member, household:, role: :member, user: create(:user, email: "deja@example.com"))

    expect(invite(role: "owner", email: "a@example.com").failure.last.errors).to include(:role)
    expect(invite(email: "").failure.last.errors).to include(:email)
    expect(invite(email: "pas-un-email").failure.last.errors).to include(:email)
    expect(invite(email: "Deja@example.com").failure.last.errors).to include(:email)
    expect(household.members.where(user: nil)).to be_empty
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "reserves nothing when the e-mail cannot be sent" do
    [ Errno::ECONNREFUSED, SocketError, OpenSSL::SSL::SSLError ].each do |error|
      allow(InvitationsMailer).to receive(:invite).and_raise(error)

      expect(invite(email: "lea@example.com").failure.first).to eq(:not_sent)
    end
    expect(household.members.where(user: nil)).to be_empty
  end

  it "reserves a guest's place with what is opened to them, ready when they join" do
    plant = create(:plant, household:)
    invitation = invite({ role: "guest", email: "marc@example.com" },
                        { subjects: [ "Plant:#{plant.id}" ], ends_on: "2027-01-05" }).value!

    expect(invitation.household_member).to have_attributes(role: "guest", access_ends_on: Date.new(2027, 1, 5))
    expect(invitation.household_member.guest_accesses.map(&:subject)).to eq([ plant ])
  end
end
