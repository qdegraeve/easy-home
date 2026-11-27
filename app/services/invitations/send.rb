module Invitations
  # E-mails the link of an invitation whose token was just generated (Create, Renew). Sent now, not through a job: the
  # token must not be stored. A failure is told to the manager instead of being lost.
  class Send
    include Dry::Monads[:result]

    def call(invitation:)
      InvitationsMailer.invite(invitation, invitation.token).deliver_now
      Success(invitation)
    # Any failure of the delivery (SMTP, DNS, TLS, timeout…): reported, and said to the manager.
    rescue StandardError => error
      Rails.error.report(error, handled: true)
      Failure[:not_sent, invitation]
    end
  end
end
