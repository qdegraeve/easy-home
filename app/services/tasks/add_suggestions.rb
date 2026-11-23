module Tasks
  # Adds the suggestions checked on the screen after adding an equipment ("Ajouter des tâches d'entretien ?"): each one
  # copied into a task (TaskForm.from_suggestion), on its first date (one period from today after the last time, the
  # next yearly date, none when needed), all or nothing. Only the suggestions of that subject not already added; the
  # others are ignored.
  class AddSuggestions
    include Dry::Monads[:result, :do]

    def call(subject:, keys:, today: Time.zone.today)
      suggestions = Catalogue.suggestions_for(subject, existing_keys: subject.tasks.used_suggestion_keys)
        .select { |suggestion| Array(keys).include?(suggestion.key) }
      return Failure[:none_selected, subject] if suggestions.empty?

      tasks = ActiveRecord::Base.transaction do
        suggestions.map do |suggestion|
          yield Tasks::Add.new.call(subject:, params: TaskForm.from_suggestion(suggestion, today:).attributes)
        end
      end

      Success(tasks)
    end
  end
end
