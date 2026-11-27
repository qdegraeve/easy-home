require "rails_helper"

RSpec.describe Members::SetGuestAccess do
  let(:household) { create(:household) }
  let(:guest) { create(:household_member, household:, role: :guest) }
  let(:ficus) { create(:plant, household:) }

  it "replaces the subjects opened, ignoring those of another household" do
    other = create(:plant)
    described_class.new.call(member: guest, params: { subjects: [ "Plant:#{ficus.id}", "Household:#{household.id}" ] })

    described_class.new.call(member: guest, params: { subjects: [ "Plant:#{ficus.id}", "Plant:#{other.id}", "Bad:1" ] })

    expect(guest.guest_accesses.map(&:subject)).to eq([ ficus ])
  end

  it "refuses a period that ends before it starts" do
    result = described_class.new.call(member: guest, params: { starts_on: "2026-12-20", ends_on: "2026-12-19" })

    expect(result.failure.first).to eq(:invalid)
    expect(guest.reload.access_starts_on).to be_nil
  end

  it "loses the accesses when the guest becomes a member" do
    create(:household_member, household:, role: :manager)
    described_class.new.call(member: guest, params: { full_access: "1", subjects: [ "Plant:#{ficus.id}" ] })

    Members::ChangeRole.new.call(member: guest, role: "member")

    expect(guest.reload).to have_attributes(role: "member", guest_full_access: false)
    expect(guest.guest_accesses).to be_empty
  end
end
