# Budget de temps par spec, appliqué en CI : une suite lente finit par ne plus être lancée.
# Une spec qui dépasse son budget échoue avec un message explicite. On la rend plus
# rapide (build au lieu de create, moins de navigation, données minimales) plutôt
# que de relever le budget. Voir docs/tests.md.
module TimeBudget
  # Secondes par exemple.
  LIMITS = { system: 8.0, other: 1.0 }.freeze
  # Marge pour le premier exemple de chaque sorte (chargement, démarrage de Chrome).
  WARMUP = 10.0

  def self.kind(example)
    example.metadata[:type] == :system ? :system : :other
  end
end

if ENV["CI"]
  RSpec.configure do |config|
    warmed_up = {}

    config.around(:each) do |example|
      kind = TimeBudget.kind(example)
      limit = TimeBudget::LIMITS.fetch(kind)
      limit += TimeBudget::WARMUP unless warmed_up[kind]
      warmed_up[kind] = true
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      example.run

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      next if example.exception || elapsed <= limit

      raise "Spec trop lente : #{elapsed.round(2)} s pour un budget de #{limit} s (voir docs/tests.md)"
    end
  end
end
