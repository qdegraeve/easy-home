module Members
  # Removes someone from a household (ADR 0019): a manager removes a member, or anyone leaves. The account stays, and
  # so do its lines in the journal. Under the household lock: the last manager can neither leave nor be removed.
  class Remove
    include Dry::Monads[:result, :do]

    def call(member:)
      member.household.with_lock do
        yield LastManager.new.ensure_not(member)

        member.destroy!
      end
      Success(member)
    end
  end
end
