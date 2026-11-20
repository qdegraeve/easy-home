require "rails_helper"

RSpec.describe Plants::AskAgain do
  include ActiveJob::TestHelper

  let(:question) { create(:plant_analysis_question, status: :failed, error: "external_error: x") }

  it "puts a failed question back in the queue" do
    expect { described_class.new.call(question:) }.to have_enqueued_job(AnswerQuestionJob).with(question)

    expect(question.reload).to have_attributes(status: "pending", error: nil)
  end

  it "refuses a question that did not fail" do
    question.update!(status: :done, answer: "Oui.")

    expect(described_class.new.call(question:).failure.first).to eq(:not_failed)
  end

  it "refuses while another question of the analysis waits for its answer" do
    create(:plant_analysis_question, analysis: question.analysis)

    expect(described_class.new.call(question:).failure.first).to eq(:already_pending)
    expect(question.reload).to be_failed
  end

  it "refuses on an archived plant" do
    question.analysis.plant.update!(archived_at: Time.current)

    expect(described_class.new.call(question:).failure.first).to eq(:subject_archived)
  end
end
