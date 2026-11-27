module Members
  # A household always keeps a manager who joined: the one guard of ChangeRole and Remove, called under the
  # household lock.
  class LastManager
    include Dry::Monads[:result]

    def ensure_not(member)
      return Success(member) unless member.manager? && !member.pending?
      return Success(member) if member.household.members.joined.manager.where.not(id: member.id).exists?

      Failure[:last_manager, member]
    end
  end
end
