module Households
  class Create
    include Dry::Monads[:result]

    def call(user:, params:)
      household = Household.new(name: params[:name])
      return Failure[:invalid, household] unless household.valid?

      ActiveRecord::Base.transaction do
        household.save!
        Membership.create!(user:, household:, role: :owner)
      end

      Success(household)
    end
  end
end
