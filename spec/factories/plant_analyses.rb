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

    trait :with_proposals do
      done
      species_name { "Citrus limon" }
      species_common_name { "Citronnier" }
      species_confidence { :high }
      watering_interval_days { 4 }
      actions { [ { "title" => "Pailler le pied", "details" => "Garde la terre fraîche.", "due_in_days" => 3 } ] }
    end
  end
end
