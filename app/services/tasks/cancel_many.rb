module Tasks
  # Cancels several completions in one gesture (the "Annuler" of a toast). Each one goes through
  # Tasks::CancelCompletion on its own; fails only when nothing could be cancelled.
  class CancelMany
    include Dry::Monads[:result]

    def call(occurrences:)
      cancelled = occurrences.filter_map do |occurrence|
        Tasks::CancelCompletion.new.call(occurrence:).value_or(nil)
      end

      cancelled.any? ? Success(cancelled) : Failure[:nothing_cancelled]
    end
  end
end
