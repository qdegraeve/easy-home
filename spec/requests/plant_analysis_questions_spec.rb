require "rails_helper"

RSpec.describe "Plant analysis questions", type: :request do
  include ActiveJob::TestHelper

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }
  let(:plant) { create(:plant, :watered, household:, name: "Citronnier") }
  let(:analysis) { create(:plant_analysis, :done, plant:) }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  it "asks a question, then shows the answer under the analysis" do
    sign_in(user)

    params = { plant_analysis_question: { body: "Faut-il pailler ?" } }
    expect { post plant_analysis_questions_path(plant, analysis), params: }.to have_enqueued_job(AnswerQuestionJob)
    expect(response).to redirect_to(plant_path(plant))
    follow_redirect!
    expect(response.body).to include("Question envoyée", "Faut-il pailler ?", "Réponse en cours")
    expect(response.body).not_to include("Envoyer la question")

    perform_enqueued_jobs
    get plant_path(plant)
    expect(response.body).to include("Oui, le paillis suffit.", "Envoyer la question")
  end

  it "shows the thread on the analysis page, which refreshes itself when the answer comes" do
    create(:plant_analysis_question, analysis:, body: "Faut-il pailler ?")
    sign_in(user)

    get plant_analysis_path(plant, analysis)

    expect(response.body).to include("Faut-il pailler ?", "Réponse en cours", "turbo-cable-stream-source")
    expect(response.body).to include('<meta name="turbo-refresh-method" content="morph">')
  end

  it "refuses a question on an analysis of another plant" do
    other = create(:plant_analysis, :done, plant: create(:plant, household:))
    sign_in(user)

    post plant_analysis_questions_path(plant, other), params: { plant_analysis_question: { body: "Alors ?" } }

    expect(response).to have_http_status(:not_found)
  end

  it "forbids a question on an analysis that is not done" do
    analysis.update!(status: :failed)
    sign_in(user)

    post plant_analysis_questions_path(plant, analysis), params: { plant_analysis_question: { body: "Alors ?" } }

    expect(response).to have_http_status(:forbidden)
  end

  it "re-renders the form when the question is empty" do
    sign_in(user)

    post plant_analysis_questions_path(plant, analysis), params: { plant_analysis_question: { body: "" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Poser une question", "Question doit être rempli(e)")
  end

  it "answers 400 to a malformed request" do
    sign_in(user)

    post plant_analysis_questions_path(plant, analysis), params: { plant_analysis_question: "foo" }

    expect(response).to have_http_status(:bad_request)
  end

  it "refuses a question while another one waits for its answer" do
    create(:plant_analysis_question, analysis:)
    sign_in(user)

    post plant_analysis_questions_path(plant, analysis), params: { plant_analysis_question: { body: "Encore ?" } }

    expect(flash[:alert]).to eq("Une question attend déjà sa réponse.")
  end

  it "shows a failed answer with a button to ask again" do
    question = create(:plant_analysis_question, analysis:, status: :failed, error: "external_error: x")
    sign_in(user)

    get plant_path(plant)
    expect(response.body).to include("La réponse n&#39;a pas abouti", "Reposer la question")

    expect { post ask_again_plant_analysis_question_path(plant, analysis, question) }
      .to have_enqueued_job(AnswerQuestionJob)
    expect(question.reload).to be_pending
  end

  it "escapes the AI answer" do
    create(:plant_analysis_question, :done, analysis:, answer: %(<img src="https://evil.example/p.gif">))
    sign_in(user)

    get plant_path(plant)

    expect(response.body).not_to include("<img src=\"https://evil")
    expect(response.body).to include("&lt;img src=")
  end

  it "shows the limit instead of the form once reached" do
    create_list(:plant_analysis_question, PlantAnalysisQuestion::MAX_PER_ANALYSIS, :done, analysis:)
    sign_in(user)

    get plant_path(plant)

    expect(response.body).to include("10 questions au maximum par analyse")
    expect(response.body).not_to include("Envoyer la question")
  end

  describe "access denied" do
    it "answers 404 to a guest of the household" do
      question = create(:plant_analysis_question, analysis:, status: :failed)
      sign_in(create(:household_member, household:, role: :guest).user)

      post plant_analysis_questions_path(plant, analysis), params: { plant_analysis_question: { body: "Alors ?" } }
      expect(response).to have_http_status(:not_found)
      post ask_again_plant_analysis_question_path(plant, analysis, question)
      expect(response).to have_http_status(:not_found)
      expect(analysis.questions.count).to eq(1)
    end

    it "answers 404 to a user of another household" do
      sign_in(create(:user, :with_household))

      post plant_analysis_questions_path(plant, analysis), params: { plant_analysis_question: { body: "Alors ?" } }

      expect(response).to have_http_status(:not_found)
    end

    it "forbids a question on an archived plant" do
      plant.update!(archived_at: Time.current)
      sign_in(user)

      post plant_analysis_questions_path(plant, analysis), params: { plant_analysis_question: { body: "Alors ?" } }

      expect(response).to have_http_status(:forbidden)
      expect(analysis.questions).to be_empty
    end
  end
end
