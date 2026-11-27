module Members
  # "Renvoyer l'invitation" (ADR 0020): a new link, e-mailed again; the previous one stops working.
  class ResendsController < ApplicationController
    def create
      member = authorize(policy_scope(HouseholdMember).find(params[:member_id]), :renew?)
      result = Invitations::Renew.new.call(invitation: member.invitation)

      if result.success?
        redirect_to members_path, notice: t(".success", email: member.invitation.email)
      else
        redirect_to members_path, alert: t(".#{result.failure.first}")
      end
    end
  end
end
