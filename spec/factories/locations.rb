FactoryBot.define do
  factory :location do
    household
    sequence(:name) { |n| "Emplacement #{n}" }
    exposure { :full_sun }
  end
end
