module Invitations
  # Rejoindre un foyer (ADR 0019, 0020): the person the invitation was e-mailed to takes the reserved place, signed in
  # with that address, or with the account created from the link for that address (clicking the link proved it). The
  # invitation and the household are locked: two taps on "Rejoindre" use the link once. Someone who already belongs to
  # the household does not use it up.
  class Accept
    include Dry::Monads[:result, :do]

    # user: the signed-in user; account: { name:, password:, password_confirmation: } to create one instead.
    def call(token:, user: nil, account: nil)
      ActiveRecord::Base.transaction do
        invitation = yield find(token)
        member = invitation.household_member
        # The household too: a deletion of the account of its last person (Accounts::Destroy) waits, or goes first.
        member.household.lock!
        user ||= yield create_account(invitation, account)
        yield ensure_addressee(invitation, user)
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

    # The e-mail is the invitation's, never one from the form.
    def create_account(invitation, account)
      user = User.new(account.to_h.slice(:name, :password, :password_confirmation).merge(email: invitation.email))
      user.errors.add(:password, :blank) if user.password.blank?
      user.save if user.errors.none?
      user.persisted? ? Success(user) : Failure[:invalid_account, user]
    end

    def ensure_addressee(invitation, user)
      user.email == invitation.email ? Success(user) : Failure[:other_account, invitation]
    end

    def ensure_newcomer(household, user)
      return Success(user) unless household.members.exists?(user:)

      Failure[:already_member, household]
    end
  end
end
