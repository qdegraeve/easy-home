require "rails_helper"

RSpec.describe Members::Remove do
  let(:household) { create(:household) }
  let!(:manager) { create(:household_member, household:, role: :manager) }

  it "removes a member, keeping the account and what they did" do
    member = create(:household_member, household:, role: :member)
    task = create(:task, household:)
    done = task.occurrences.create!(due_at: Time.current, status: :done, completed_at: Time.current,
                                    completed_by: member.user)

    described_class.new.call(member:)

    expect(HouseholdMember.exists?(member.id)).to be(false)
    expect(done.reload.completed_by).to eq(member.user)
  end

  it "removes a manager while another one stays, never the last one" do
    other = create(:household_member, household:, role: :manager)

    expect(described_class.new.call(member: other)).to be_success
    expect(described_class.new.call(member: manager).failure).to eq([ :last_manager, manager ])
    expect(manager.reload).to be_present
  end
end
