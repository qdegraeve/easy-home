require "rails_helper"

RSpec.describe GuestVisibilityQuery do
  let(:household) { create(:household) }
  let(:ficus) { create(:plant, household:, name: "Ficus") }
  let(:pool) { create(:equipment, household:, name: "Piscine") }
  let!(:ficus_task) { create(:task, household:, subject: ficus) }
  let!(:pool_task) { create(:task, household:, subject: pool, template_key: nil) }
  let!(:bins) { create(:task, household:, subject: nil, template_key: nil, title: "Poubelle") }
  let!(:elsewhere) { create(:task, household: create(:household), subject: nil, template_key: nil) }
  let(:guest) { create(:household_member, household:, role: :guest) }

  def open(*subjects, **period)
    keys = subjects.map { "#{_1.class.name}:#{_1.id}" }
    Members::SetGuestAccess.new.call(member: guest, params: { subjects: keys, **period })
  end

  it "sees the tasks of the subjects opened, the house tasks through the household, nothing else" do
    open(ficus, household)

    expect(described_class.new(guest.user).tasks).to contain_exactly(ficus_task, bins)
    expect(described_class.new(guest.user).subjects(Plant)).to eq([ ficus ])
    expect(described_class.new(guest.user).subjects(Equipment)).to be_empty
  end

  it "sees everything of the household with Tout ouvrir, tasks added later included" do
    Members::SetGuestAccess.new.call(member: guest, params: { full_access: "1" })
    later = create(:task, household:, subject: pool, template_key: nil)

    expect(described_class.new(guest.user).tasks).to contain_exactly(ficus_task, pool_task, bins, later)
    expect(described_class.new(guest.user).subjects(Equipment)).to eq([ pool ])
  end

  it "sees nothing outside the period, everything of it on its first and last day" do
    open(ficus, starts_on: "2026-12-20", ends_on: "2027-01-05")

    expect(described_class.new(guest.user, on: Date.new(2026, 12, 19)).tasks).to be_empty
    expect(described_class.new(guest.user, on: Date.new(2026, 12, 20)).tasks).to eq([ ficus_task ])
    expect(described_class.new(guest.user, on: Date.new(2027, 1, 5)).tasks).to eq([ ficus_task ])
    expect(described_class.new(guest.user, on: Date.new(2027, 1, 6)).tasks).to be_empty
  end

  it "gives nothing to a member through this query, nor to nobody" do
    member = create(:household_member, household:, role: :member)

    expect(described_class.new(member.user).tasks).to be_empty
    expect(described_class.new(nil).tasks).to be_empty
  end
end
