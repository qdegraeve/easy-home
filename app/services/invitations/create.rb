module Invitations
  # "Inviter quelqu'un" (ADR 0019): reserves a place in the household with its role, and the link that gives it. The
  # token is only on the returned invitation (#token): it is shown once.
  class Create
    include Dry::Monads[:result]

    # Guests come with their accesses (PR 4 of the series).
    ROLES = %w[member manager].freeze

    def call(household:, created_by:, params:)
      member = household.members.new(role: params[:role], invitee_name: params[:invitee_name])
      member.errors.add(:role, :inclusion) unless ROLES.include?(params[:role].to_s)
      invitation = member.build_invitation(created_by:).renew_token
      return Failure[:invalid, member] if member.errors.any? || !member.valid?

      member.save!
      Success(invitation)
    end
  end
end
