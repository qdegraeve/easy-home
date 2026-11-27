# "Membres du foyer" (ADR 0019): who is in the current household, the invitations still open, and inviting someone.
class MembersController < ApplicationController
  before_action :set_household

  def index
    authorize HouseholdMember.new(household: @household)
    @members = @household.members.joined.includes(:user).order(:role, :id)
    @invited = @household.members.invited.includes(:invitation).order(:id)
  end

  def new
    @member = authorize(HouseholdMember.new(household: @household, role: :member))
  end

  def create
    authorize HouseholdMember.new(household: @household)
    result = Invitations::Create.new.call(household: @household, created_by: Current.user, params: member_params)

    if result.success?
      invitation = result.value!
      # Shown once on the next page: only the digest is kept.
      flash[:invitation_token] = invitation.token
      redirect_to member_link_path(invitation.household_member)
    else
      _code, @member = result.failure
      render :new, status: :unprocessable_content
    end
  end

  # Cancels an invitation not accepted yet: the reserved place goes with it.
  def destroy
    member = authorize(policy_scope(HouseholdMember).find(params[:id]))
    member.destroy!
    redirect_to members_path, notice: t(".success")
  end

  private

  def set_household
    @household = current_household
    redirect_to(new_household_path) unless @household
  end

  def member_params
    params.expect(household_member: [ :role, :invitee_name ])
  end
end
