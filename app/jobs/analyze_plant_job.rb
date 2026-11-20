# Runs one AI analysis. One at a time across the app (the Claude plan quota is shared), and no automatic retry: a
# failed analysis shows its error and the user restarts it (ADR 0008).
class AnalyzePlantJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "plant_analysis", duration: 10.minutes

  discard_on ActiveJob::DeserializationError

  def perform(analysis)
    Plants::Analyze.new.call(analysis:)
  rescue StandardError => error
    fail_pending(analysis.reload, error)
    raise
  end

  private

  # Bypasses validations on purpose: the analysis must leave the pending state whatever its content. An analysis
  # already done or failed keeps its result.
  def fail_pending(analysis, error)
    return unless analysis.pending?

    analysis.update_columns(
      status: "failed",
      error: "unexpected: #{error.class}".truncate(250),
      finished_at: Time.current
    )
    analysis.plant.broadcast_refresh
  end
end
