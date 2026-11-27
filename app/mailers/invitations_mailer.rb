# The invitation to join a household (ADR 0020): sent to the address the manager typed. The token is passed here and
# never stored (only its digest is), so the e-mail is sent right away rather than through a job.
class InvitationsMailer < ApplicationMailer
  def invite(invitation, token)
    @invitation = invitation
    @url = invitation_url(token)
    @household = invitation.household
    @inviter = invitation.created_by&.display_name
    mail subject: t(".subject", household: @household.name), to: invitation.email
  end
end
