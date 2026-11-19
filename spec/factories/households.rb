FactoryBot.define do
  factory :household do
    name { "Maison de test" }
  end

  factory :membership do
    user
    household
    role { :owner }
  end
end
