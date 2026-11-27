# "Membres du foyer" (ADR 0019): who is in the current household, the invitations still open, inviting someone,
# changing a role, removing someone; and leaving a household, from "Mes foyers".
class MembersController < ApplicationController
  before_action :set_household, only: %i[index new create]

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

  def edit
    @member = authorize(policy_scope(HouseholdMember).joined.find(params[:id]))
  end

  def update
    @member = authorize(policy_scope(HouseholdMember).joined.find(params[:id]))
    result = Members::ChangeRole.new.call(member: @member, role: params.dig(:household_member, :role))

    if result.success?
      redirect_to members_path, notice: t(".success", name: @member.user.display_name)
    else
      redirect_to members_path, alert: t(".#{result.failure.first}")
    end
  end

  # Cancels an invitation (its place goes with it), removes someone, or leaves the household.
  def destroy
    member = authorize(policy_scope(HouseholdMember).find(params[:id]))
    return cancel(member) if member.pending?

    leaving = member.user_id == Current.user.id
    back = leaving ? households_path : members_path
    if Members::Remove.new.call(member:).success?
      notice = leaving ? t(".left", name: member.household.name) : t(".removed", name: member.user.display_name)
      redirect_to back, notice:
    else
      redirect_to back, alert: t(".last_manager")
    end
  end

  private

  def set_household
    @household = current_household
    redirect_to(new_household_path) unless @household
  end

  def cancel(member)
    member.destroy!
    redirect_to members_path, notice: t(".cancelled")
  end

  def member_params
    params.expect(household_member: [ :role, :invitee_name ])
  end
end
