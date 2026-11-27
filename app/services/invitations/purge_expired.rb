module Invitations
  # Deletes the places still reserved by an expired invitation: nobody can take them any more. An accepted invitation
  # stays, with its place.
  class PurgeExpired
    include Dry::Monads[:result]

    def call
      places = HouseholdMember.where(user_id: nil)
        .where(id: Invitation.where(accepted_at: nil, expires_at: ...Time.current).select(:household_member_id))
      Success(places.destroy_all.size)
    end
  end
end
