require "rails_helper"

RSpec.describe Members::ChangeRole do
  let(:household) { create(:household) }
  let!(:manager) { create(:household_member, household:, role: :manager) }

  it "turns a member into a manager and back while another manager stays" do
    member = create(:household_member, household:, role: :member)

    expect(described_class.new.call(member:, role: "manager").value!).to be_manager
    expect(described_class.new.call(member: manager, role: "member").value!).to be_member
  end

  it "keeps the last manager, even with a reserved manager place" do
    create(:invitation, household_member: build(:household_member, household:, user: nil, role: :manager))

    expect(described_class.new.call(member: manager, role: "member").failure).to eq([ :last_manager, manager ])
    expect(manager.reload).to be_manager
  end

  it "refuses a guest role for now, and a reserved place" do
    member = create(:household_member, household:, role: :member)
    pending = create(:invitation, household_member: build(:household_member, household:, user: nil)).household_member

    expect(described_class.new.call(member:, role: "guest").failure.first).to eq(:invalid_role)
    expect(described_class.new.call(member: pending, role: "manager").failure.first).to eq(:invalid_role)
  end
end
