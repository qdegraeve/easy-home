module Invitations
  # "Inviter quelqu'un" (ADR 0019): reserves a place in the household with its role (and, for a guest, what is opened
  # to them), and the link that gives it. The token is only on the returned invitation (#token): it is shown once.
  class Create
    include Dry::Monads[:result]

    ROLES = %w[member manager guest].freeze

    # access: for a guest, what is opened to them (Members::SetGuestAccess), ready when they join.
    def call(household:, created_by:, params:, access: {})
      member = household.members.new(role: params[:role], invitee_name: params[:invitee_name])
      member.errors.add(:role, :inclusion) unless ROLES.include?(params[:role].to_s)
      invitation = member.build_invitation(created_by:).renew_token
      return Failure[:invalid, member] if member.errors.any? || !member.valid?

      access_result = nil
      ActiveRecord::Base.transaction do
        member.save!
        access_result = Members::SetGuestAccess.new.call(member:, params: access) if member.guest?
        raise ActiveRecord::Rollback if access_result&.failure?
      end
      return Failure[:invalid, member] if access_result&.failure?

      Success(invitation)
    end
  end
end
