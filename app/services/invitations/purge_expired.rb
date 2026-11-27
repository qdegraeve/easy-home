module Invitations
  # Deletes the places still reserved by an expired invitation: nobody can take them any more. An accepted invitation
  # stays, with its place. Each invitation is locked and checked again, like Accept and Renew lock it: one renewed
  # ("Nouveau lien") or accepted meanwhile stays.
  class PurgeExpired
    include Dry::Monads[:result]

    def call
      purged = Invitation.where(accepted_at: nil, expires_at: ...Time.current).find_each.count do |invitation|
        invitation.with_lock do
          place = invitation.household_member
          next false if invitation.accepted_at || invitation.usable? || !place.pending?

          place.destroy!
        end
      end
      Success(purged)
    end
  end
end
