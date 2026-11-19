FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password" }

    trait :with_household do
      after(:create) { |user| create(:membership, user:) }
    end
  end
end
