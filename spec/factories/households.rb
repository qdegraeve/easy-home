FactoryBot.define do
  factory :household do
    name { "Maison de test" }
  end

  factory :household_member do
    user
    household
    role { :owner }
  end
end
