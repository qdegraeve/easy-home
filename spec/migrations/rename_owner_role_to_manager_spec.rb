require "rails_helper"
require Rails.root.join("db/migrate/20261127090000_rename_owner_role_to_manager")

# Data transformation (docs/tests.md): the owners of the households become their managers, and back.
RSpec.describe RenameOwnerRoleToManager do
  let(:migration) { described_class.new.tap { _1.verbose = false } }

  it "turns the owners into managers and leaves the other roles, then undoes it" do
    owner = create(:household_member, role: :manager)
    owner.update_columns(role: "owner")
    member = create(:household_member, role: :member)

    migration.up
    expect(owner.reload).to be_manager
    expect(member.reload).to be_member

    migration.down
    expect(owner.reload.read_attribute_before_type_cast(:role)).to eq("owner")
    expect(member.reload).to be_member
  end
end
