# What a user sees as a guest today (ADR 0019): in the households where they are a guest and their period includes
# today, the tasks of the subjects opened to them (a plant, an equipment, or the household for the tasks of the
# house), or all of them with "Tout ouvrir". Read by the policies, so that every screen, the digest and the reminders
# share one definition. Returns composable relations; managers and members are handled by the policies themselves.
#
#   GuestVisibilityQuery.new(user).tasks          # => Task relation
#   GuestVisibilityQuery.new(user).subjects(Plant) # => Plant relation
class GuestVisibilityQuery
  def initialize(user, on: Time.zone.today)
    @user = user
    @on = on
  end

  def tasks
    return Task.none unless user

    full = Task.where(household_id: guests.where(guest_full_access: true).select(:household_id))
    opened = Task.where(<<~SQL.squish, guests.select(:id))
      EXISTS (
        SELECT 1 FROM guest_accesses
        WHERE guest_accesses.household_member_id IN (?)
          AND (
            (guest_accesses.subject_type = tasks.subject_type AND guest_accesses.subject_id = tasks.subject_id)
            OR (guest_accesses.subject_type = 'Household' AND tasks.subject_id IS NULL
                AND guest_accesses.subject_id = tasks.household_id)
          )
      )
    SQL
    full.or(opened)
  end

  # The plants or equipment opened to the guest (all of a household with "Tout ouvrir").
  def subjects(model)
    return model.none unless user

    opened = GuestAccess.where(household_member_id: guests.select(:id), subject_type: model.polymorphic_name)
    model.where(household_id: guests.where(guest_full_access: true).select(:household_id))
      .or(model.where(id: opened.select(:subject_id)))
  end

  private

  attr_reader :user, :on

  def guests
    HouseholdMember.guests_on(on).where(user:)
  end
end
