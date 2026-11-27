module Invitations
  # Rejoindre un foyer (ADR 0019): the signed-in user, or the account created from the link, takes the reserved place.
  # The invitation is locked: two taps on "Rejoindre" use the link once. Someone who already belongs to the household
  # does not use it up.
  class Accept
    include Dry::Monads[:result, :do]

    # user: the signed-in user; account: { name:, email:, password:, password_confirmation: } to create one instead.
    def call(token:, user: nil, account: nil)
      ActiveRecord::Base.transaction do
        invitation = yield find(token)
        member = invitation.household_member
        # The household too: a deletion of the account of its last person (Accounts::Destroy) waits, or goes first.
        member.household.lock!
        user ||= yield create_account(account)
        yield ensure_newcomer(member.household, user)

        member.update!(user:)
        invitation.update!(accepted_at: Time.current)
        Success(member)
      end
    end

    private

    def find(token)
      invitation = Invitation.lock.find_usable(token)
      invitation ? Success(invitation) : Failure[:unusable]
    end

    def create_account(account)
      user = User.new(account.to_h.slice(:name, :email, :password, :password_confirmation))
      user.errors.add(:password, :blank) if user.password.blank?
      user.save if user.errors.none?
      user.persisted? ? Success(user) : Failure[:invalid_account, user]
    end

    def ensure_newcomer(household, user)
      return Success(user) unless household.members.exists?(user:)

      Failure[:already_member, household]
    end
  end
end
