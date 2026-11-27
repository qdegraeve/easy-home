module Accounts
  # "Supprimer mon compte" (ADR 0019, required by the app stores): the account, its sessions and phones, and its places
  # in the households go. A household where the person is alone goes with it (plants, equipment, tasks, photos); the
  # last manager of a shared household must name another one first. What the person did stays, without their name.
  #
  # Every household of the person is locked first (by id: two deletions never wait for each other), and everything is
  # checked before anything is deleted: a refusal deletes nothing, photo files included.
  class Destroy
    include Dry::Monads[:result, :do]

    def call(user:, password:)
      return Failure[:wrong_password, user] unless user.authenticate(password.to_s)

      ActiveRecord::Base.transaction do
        Household.where(id: user.household_members.select(:household_id)).order(:id).lock.to_a
        yield ensure_handed_over(user)

        self.class.households_alone(user).find_each(&:destroy!)
        user.destroy!
      end
      Success(user)
    end

    # The households that would go with the account: those where the person is alone. Said before confirming.
    def self.households_alone(user)
      user.households.where.not(id: HouseholdMember.joined.where.not(user:).select(:household_id))
    end

    # The shared households where the person is the last manager: they must name another one first.
    def self.households_to_hand_over(user)
      managed = user.household_members.manager.select(:household_id)
      others = HouseholdMember.joined.where.not(user:)
      Household.where(id: managed)
        .where(id: others.select(:household_id))
        .where.not(id: others.manager.select(:household_id))
    end

    private

    def ensure_handed_over(user)
      households = self.class.households_to_hand_over(user).to_a
      households.empty? ? Success(user) : Failure[:last_manager, households]
    end
  end
end
