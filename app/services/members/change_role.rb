module Members
  # A manager changes the role of someone who joined (ADR 0019): member ↔ manager. Under the household lock, so that
  # two managers demoting each other at once never leave it without one.
  class ChangeRole
    include Dry::Monads[:result, :do]

    ROLES = %w[member manager].freeze

    def call(member:, role:)
      member.household.with_lock do
        # Read again under the lock: the role may have changed since the page was loaded.
        return Failure[:gone, member] unless member.class.exists?(member.id)

        member.reload
        return Failure[:invalid_role, member] unless ROLES.include?(role.to_s) && !member.pending?
        yield LastManager.new.ensure_not(member) unless role.to_s == "manager"

        # A guest who becomes a member sees everything: their accesses go.
        member.guest_accesses.delete_all if member.guest?
        member.update!(role:, guest_full_access: false, access_starts_on: nil, access_ends_on: nil)
      end
      Success(member)
    end
  end
end
