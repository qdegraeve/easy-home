module PlantAnalyzer
  # The text sent with a follow-up question: the context of the analysis (never the address, see Context), the
  # analysis itself, the conversation so far and the new question. The photos are numbered in the order they are
  # sent: the analysis photos oldest first, then the photos attached to the questions.
  class FollowUpContext
    def initialize(question, today: Time.zone.today)
      @question = question
      @analysis = question.analysis
      @today = today
    end

    # The photos to send, in the order the text numbers them.
    def photos
      @photos ||= analysis.photos_oldest_first + thread.filter_map(&:photo)
    end

    def to_text
      [
        Context.new(analysis, today:).to_text,
        "",
        analysis_text,
        "",
        *conversation_lines,
        "",
        "New question from the owner#{photo_note(question)}: #{question.body}"
      ].join("\n")
    end

    private

    attr_reader :question, :analysis, :today

    # Previous questions and the current one, in order.
    def thread
      @thread ||= analysis.questions.select { |other| other.id <= question.id }
    end

    def analysis_text
      lines = [ "Your analysis of #{analysis.created_at.to_date.iso8601}:", "Health: #{analysis.health}." ]
      if analysis.species_name
        lines << "Species: #{analysis.species_name} (#{analysis.species_common_name}), " \
                 "confidence #{analysis.species_confidence}."
      end
      lines << "Suggested watering: every #{analysis.watering_interval_days} days." if analysis.watering_interval_days
      lines << "Observations: #{analysis.observations}"
      analysis.actions.each do |action|
        lines << "Action in #{action["due_in_days"]} days: #{action["title"]}. #{action["details"]}".strip
      end
      lines.join("\n")
    end

    def conversation_lines
      previous = thread - [ question ]
      return [ "No previous question." ] if previous.empty?

      [ "Conversation so far:" ] + previous.flat_map do |other|
        [ "Owner#{photo_note(other)}: #{other.body}", "You: #{other.answer || "(no answer)"}" ]
      end
    end

    def photo_note(other)
      return "" unless other.photo

      number = photos.index(other.photo) + 1
      " (with photo #{number}, taken on #{other.photo.taken_at.to_date.iso8601})"
    end
  end
end
