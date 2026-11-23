FactoryBot.define do
  factory :household do
    name { "Maison de test" }

    trait :located do
      latitude { -20.9 }
      longitude { 55.45 }
    end
  end

  factory :household_member do
    user
    household
    role { :owner }
  end
end
