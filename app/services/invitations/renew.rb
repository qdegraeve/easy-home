module Invitations
  # "Renvoyer l'invitation": a new token and 7 more days, e-mailed again; the previous link stops working, the place
  # keeps its settings. Under the invitation lock, like Accept and PurgeExpired.
  class Renew
    include Dry::Monads[:result]

    def call(invitation:)
      invitation.with_lock do
        return Failure[:accepted, invitation] if invitation.accepted_at

        invitation.renew_token.save!
      end
      Invitations::Send.new.call(invitation:)
    end
  end
end
