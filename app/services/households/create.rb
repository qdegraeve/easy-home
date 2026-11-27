module Households
  class Create
    include Dry::Monads[:result]

    def call(user:, params:)
      household = Household.new(name: params[:name])
      return Failure[:invalid, household] unless household.valid?

      ActiveRecord::Base.transaction do
        household.save!
        HouseholdMember.create!(user:, household:, role: :manager)
      end

      Success(household)
    end
  end
end
