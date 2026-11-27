module Invitations
  # "Rejoindre": the signed-in user takes the place, or the account given in the form is created for it.
  class AcceptancesController < ApplicationController
    allow_unauthenticated_access only: :create
    rate_limit(
      to: 10,
      within: 3.minutes,
      only: :create,
      with: -> { redirect_to invitation_path(params[:invitation_token]), alert: t(".rate_limited") }
    )

    def create
      signed_in = authenticated?
      result = Invitations::Accept.new.call(
        token: params[:invitation_token],
        user: Current.user,
        account: (account_params unless signed_in)
      )

      if result.success?
        member = result.value!
        start_new_session_for(member.user) unless signed_in
        session.delete(:return_to_after_authenticating)
        session[:household_id] = member.household_id
        redirect_to root_path, notice: t(".success", name: member.household.name)
      else
        failure(*result.failure)
      end
    end

    private

    def failure(code, payload = nil)
      @invitation = Invitation.find_usable(params[:invitation_token]) if code == :invalid_account
      session.delete(:return_to_after_authenticating) unless @invitation
      case code
      when :invalid_account
        return render("invitations/unusable", status: :not_found) unless @invitation # expired meanwhile

        @household = @invitation.household
        @user = payload
        render "invitations/show", status: :unprocessable_content
      when :already_member
        session[:household_id] = payload.id
        redirect_to root_path, notice: t(".already_member", name: payload.name)
      else
        render "invitations/unusable", status: :not_found
      end
    end

    def account_params
      params.expect(user: [ :name, :email, :password, :password_confirmation ])
    end
  end
end
