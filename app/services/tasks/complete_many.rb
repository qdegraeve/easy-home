module Tasks
  # Marks several occurrences as done in one gesture ("Arroser · 4"). Each one goes through Tasks::Complete on its own:
  # an occurrence already done (double tap, another member of the household) is skipped and does not prevent the
  # others. Fails only when nothing could be done.
  class CompleteMany
    include Dry::Monads[:result]

    def call(occurrences:, user:)
      completed = occurrences.filter_map do |occurrence|
        Tasks::Complete.new.call(occurrence:, user:).value_or(nil)
      end

      completed.any? ? Success(completed) : Failure[:nothing_done]
    end
  end
end
