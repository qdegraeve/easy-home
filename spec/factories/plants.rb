FactoryBot.define do
  factory :plant do
    household
    sequence(:name) { |n| "Plante #{n}" }

    # Plante telle que créée par Plants::Add : tâche d'arrosage, dernier arrosage au journal, échéance ouverte.
    trait :watered do
      transient do
        interval_days { 3 }
        last_watered_at { Time.current.beginning_of_day }
      end

      after(:create) do |plant, context|
        task = create(:task, household: plant.household, subject: plant, interval_days: context.interval_days)
        create(:task_occurrence, :done, task:, completed_at: context.last_watered_at)
        create(:task_occurrence, task:, due_at: task.recurrence.next_due_at(last_completed_at: context.last_watered_at))
      end
    end
  end
end
