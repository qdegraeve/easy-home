FactoryBot.define do
  factory :location do
    household
    sequence(:name) { |n| "Emplacement #{n}" }
    exposure { :full_sun }

    trait :rainy do
      rain_exposed { true }
    end
  end
end
