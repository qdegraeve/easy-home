FactoryBot.define do
  factory :plant_analysis do
    plant
    photos { [ association(:photo, plant:) ] }

    trait :done do
      status { :done }
      health { :ok }
      observations { "Plante en forme." }
      finished_at { Time.current }
    end
  end
end
