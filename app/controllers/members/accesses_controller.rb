module Members
  # What a guest may see and do, from their page (ADR 0019): the same settings as when they were invited.
  class AccessesController < ApplicationController
    def update
      member = authorize(policy_scope(HouseholdMember).guest.find(params[:member_id]), :access?)
      result = Members::SetGuestAccess.new.call(member:, params: GuestAccessParams.from(params))

      if result.success?
        redirect_to members_path, notice: t(".success", name: member.user&.display_name || member.invitee_name)
      else
        redirect_to edit_member_path(member), alert: result.failure.last.errors.full_messages.to_sentence
      end
    end
  end
end
