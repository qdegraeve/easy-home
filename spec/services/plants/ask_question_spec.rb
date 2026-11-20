require "rails_helper"

RSpec.describe Plants::AskQuestion do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:analysis) { create(:plant_analysis, :done) }
  let(:plant) { analysis.plant }

  def ask(params)
    described_class.new.call(analysis:, user:, params:)
  end

  it "records the question and queues its answer" do
    result = nil
    expect { result = ask(body: "  Faut-il pailler ?  ") }.to have_enqueued_job(AnswerQuestionJob)

    expect(result.value!).to have_attributes(body: "Faut-il pailler ?", status: "pending", asked_by: user, photo: nil)
  end

  it "adds the attached photo to the plant's photos" do
    file = Rack::Test::UploadedFile.new(file_fixture("plant.png"), "image/png")

    question = ask(body: "Et là ?", photo: file).value!

    expect(question.photo).to be_present
    expect(plant.photos).to include(question.photo)
  end

  it "refuses an empty question" do
    result = ask(body: " ")

    expect(result.failure.first).to eq(:invalid)
    expect(result.failure.last.errors).to include(:body)
    expect(analysis.questions).to be_empty
  end

  it "keeps neither the question nor the photo when the photo cannot be read" do
    result = ask(body: "Et là ?", photo: Rack::Test::UploadedFile.new(file_fixture("not_an_image.jpg"), "image/jpeg"))

    expect(result.failure.first).to eq(:invalid)
    expect(result.failure.last.errors).to include(:photo)
    expect(analysis.questions.count).to eq(0)
    expect(plant.photos.count).to eq(1)
  end

  it "keeps neither the question nor the photo when the photo is unreadable past the content check" do
    result = ask(body: "Et là ?", photo: uploaded_file(truncated_jpeg, "cut.jpg"))

    expect(result.failure.first).to eq(:invalid)
    expect(analysis.questions.count).to eq(0)
    expect(plant.photos.count).to eq(1)
  end

  it "refuses a question while another one waits for its answer" do
    create(:plant_analysis_question, analysis:)

    expect(ask(body: "Encore ?").failure.first).to eq(:already_pending)
  end

  it "refuses a question past the limit" do
    create_list(:plant_analysis_question, PlantAnalysisQuestion::MAX_PER_ANALYSIS, :done, analysis:)

    expect(ask(body: "Encore ?").failure.first).to eq(:too_many)
  end

  it "refuses a question on an analysis that is not done" do
    analysis.update!(status: :failed)

    expect(ask(body: "Alors ?").failure.first).to eq(:not_done)
  end

  it "refuses a question on an archived plant" do
    plant.update!(archived_at: Time.current)

    expect(ask(body: "Alors ?").failure.first).to eq(:subject_archived)
  end
end
