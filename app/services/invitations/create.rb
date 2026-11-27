module Invitations
  # "Inviter quelqu'un" (ADR 0019, 0020): reserves a place in the household with its role (and, for a guest, what is
  # opened to them), and e-mails its link to the address given: only that address can take it. The token is in the
  # e-mail only, sent right away (never stored, not even in a job). Not sent: nothing is reserved.
  class Create
    include Dry::Monads[:result, :do]

    ROLES = %w[member manager guest].freeze

    # access: for a guest, what is opened to them (Members::SetGuestAccess), ready when they join.
    def call(household:, created_by:, params:, access: {})
      member = household.members.new(role: params[:role], invitee_name: params[:invitee_name])
      invitation = member.build_invitation(created_by:, email: params[:email]).renew_token
      yield validate(member, invitation)
      yield reserve(member, access)

      Invitations::Send.new.call(invitation:).or { |failure| member.destroy! && Failure(failure) }
    end

    private

    def validate(member, invitation)
      member.errors.add(:role, :inclusion) unless ROLES.include?(member.role.to_s)
      member.valid?
      invitation.errors.each { |error| member.errors.add(:email, error.type) } unless invitation.valid?
      member.errors.add(:email, :already_member) if invitation.errors.none? && already_member?(member, invitation)
      member.errors.none? ? Success(member) : Failure[:invalid, member]
    end

    def already_member?(member, invitation)
      member.household.members.joined.joins(:user).exists?(users: { email: invitation.email })
    end

    def reserve(member, access)
      access_result = nil
      ActiveRecord::Base.transaction do
        member.save!
        access_result = Members::SetGuestAccess.new.call(member:, params: access) if member.guest?
        raise ActiveRecord::Rollback if access_result&.failure?
      end
      access_result&.failure? ? Failure[:invalid, member] : Success(member)
    end
  end
end
