module Accounts
  class Create
    include Dry::Monads[:result]

    def call(email_address:, password:, household_name:)
      user = User.new(email_address:, password:)
      household = Household.new(name: household_name)

      return Failure[:invalid, user] unless user.valid?
      return Failure[:invalid, household] unless household.valid?

      ActiveRecord::Base.transaction do
        user.save!
        household.save!
        Membership.create!(user:, household:, role: :owner)
      end

      Success(user)
    end
  end
end
