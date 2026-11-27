module Members
  # The link of an invitation: shown once, right after it is created or renewed (the token comes through the flash,
  # only its digest is kept). Lost, "Nouveau lien" replaces it.
  class LinksController < ApplicationController
    def show
      @member = authorize(policy_scope(HouseholdMember).find(params[:member_id]), :renew?)
      @token = flash[:invitation_token]
    end

    def create
      member = authorize(policy_scope(HouseholdMember).find(params[:member_id]), :renew?)
      invitation = Invitations::Renew.new.call(invitation: member.invitation).value!

      flash[:invitation_token] = invitation.token
      redirect_to member_link_path(member)
    end
  end
end
