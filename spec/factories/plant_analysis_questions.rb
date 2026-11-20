FactoryBot.define do
  factory :plant_analysis_question do
    analysis { association(:plant_analysis, :done) }
    body { "Faut-il pailler ?" }

    trait :done do
      status { :done }
      answer { "Oui, un paillis de feuilles mortes." }
      finished_at { Time.current }
    end
  end
end
