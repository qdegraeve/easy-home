require "rails_helper"

RSpec.describe Plants::AnswerQuestion do
  let(:analysis) { create(:plant_analysis, :done) }
  let(:photo) { create(:photo, plant: analysis.plant) }
  let(:question) { create(:plant_analysis_question, analysis:, body: "Et là ?", photo:) }

  it "stores the answer, sending the analysis photos and the attached one, then refreshes the plant pages" do
    expect { described_class.new.call(question:) }
      .to have_broadcasted_to(analysis.plant.to_gid_param).from_channel(Turbo::StreamsChannel)

    expect(question.reload).to have_attributes(status: "done", answer: FakePlantAnalyzer::FOLLOW_UP, error: nil)
    call = @fake_plant_analyzer.calls.sole
    expect(call).to include(follow_up: true)
    expect(call[:images].size).to eq(2)
    expect(call[:text]).to end_with("New question from the owner (with photo 2, taken on " \
                                    "#{photo.taken_at.to_date.iso8601}): Et là ?")
  end

  it "records the failure of the AI" do
    @fake_plant_analyzer.error = "claude failed: quota"

    expect(described_class.new.call(question:)).to be_failure
    expect(question.reload).to have_attributes(status: "failed", error: "external_error: claude failed: quota")
  end

  it "refuses an empty or too long answer" do
    [ " ", "a" * (PlantAnalyzer::MAX_ANSWER_LENGTH + 1) ].each do |answer|
      question.update!(status: :pending, error: nil)
      @fake_plant_analyzer.follow_up = answer

      described_class.new.call(question:)

      expect(question.reload).to have_attributes(status: "failed", answer: nil)
      expect(question.error).to start_with("invalid_answer")
    end
  end

  it "does nothing for a question already answered" do
    question.update!(status: :done, answer: "Déjà répondu.")

    expect(described_class.new.call(question:).failure.first).to eq(:not_pending)
    expect(@fake_plant_analyzer.calls).to be_empty
  end
end
