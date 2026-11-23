FactoryBot.define do
  factory :equipment do
    household
    kind { "dishwasher" }
    sequence(:name) { |n| "Équipement #{n}" }
  end
end
