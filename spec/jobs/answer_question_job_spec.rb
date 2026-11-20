require "rails_helper"

RSpec.describe AnswerQuestionJob do
  let(:question) { create(:plant_analysis_question) }

  it "answers the question" do
    described_class.perform_now(question)

    expect(question.reload).to be_done
  end

  it "marks the question failed on an unexpected error and refreshes the page, without retrying" do
    allow(Plants::AnswerQuestion).to receive(:new).and_raise(ArgumentError, "boom")

    expect { described_class.perform_now(question) }
      .to raise_error(ArgumentError)
      .and have_broadcasted_to(question.analysis.plant.to_gid_param).from_channel(Turbo::StreamsChannel)
    expect(question.reload).to have_attributes(status: "failed", error: "unexpected: ArgumentError")
  end
end
