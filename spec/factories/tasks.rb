FactoryBot.define do
  factory :task do
    household
    title { "Arrosage" }
    template_key { Plant::WATERING_TEMPLATE_KEY }
    recurrence_type { :sliding }
    transient { interval_days { 3 } }
    recurrence_config { { "interval" => interval_days, "unit" => "days" } }
  end

  factory :task_occurrence do
    task
    due_at { Time.current.beginning_of_day }

    trait :done do
      status { :done }
      completed_at { Time.current }
      due_at { completed_at }
    end
  end
end
