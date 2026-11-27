module Invitations
  # "Nouveau lien": the link was lost (only its digest is kept). A new token and 7 more days; the old link stops
  # working, the place keeps its settings.
  class Renew
    include Dry::Monads[:result]

    def call(invitation:)
      return Failure[:accepted, invitation] if invitation.accepted_at

      invitation.renew_token.save!
      Success(invitation)
    end
  end
end
