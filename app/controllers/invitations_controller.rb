# The page of an invitation link (ADR 0019): join the household, signed in or not. Without an account, the account
# is created here: the only way to sign up. Expired, used and unknown links get the same answer.
class InvitationsController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    @invitation = Invitation.find_usable(params[:token])
    return render(:unusable, status: :not_found) unless @invitation

    @household = @invitation.household
    @already_member = authenticated? && @household.members.exists?(user: Current.user)
    # Signed in with another address than the one invited: the invitation is not for this account.
    @other_account = authenticated? && Current.user.email != @invitation.email
    # "J'ai déjà un compte": back here once signed in.
    session[:return_to_after_authenticating] = request.url unless authenticated?
    @user = User.new(email: @invitation.email)
  end
end
