FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }

    trait :with_household do
      after(:create) { |user| create(:household_member, user:) }
    end
  end
end
