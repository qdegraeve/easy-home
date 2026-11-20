# Answers one follow-up question. It shares the concurrency group and key of the analyses (Solid Queue prefixes the
# key with the group, the job class by default): one call to Claude at a time across the app. No automatic retry: a failed question shows its error and the user asks again (ADR 0008).
class AnswerQuestionJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "claude", group: "plant_analysis", duration: 10.minutes

  discard_on ActiveJob::DeserializationError

  def perform(question)
    Plants::AnswerQuestion.new.call(question:)
  rescue StandardError => error
    fail_pending(PlantAnalysisQuestion.find_by(id: question.id), error) # gone when the plant was deleted meanwhile
    raise
  end

  private

  # Bypasses validations on purpose: the question must leave the pending state whatever its content.
  def fail_pending(question, error)
    return unless question&.pending?

    question.update_columns(
      status: "failed",
      error: "unexpected: #{error.class}".truncate(250),
      finished_at: Time.current
    )
    question.analysis.plant.broadcast_refresh
  end
end
