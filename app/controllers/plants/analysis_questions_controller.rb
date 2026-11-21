module Plants
  # Follow-up questions on an AI analysis (ADR 0008).
  class AnalysisQuestionsController < ApplicationController
    def create
      @plant, @analysis = find_plant_and_analysis
      # By id: built from the association, the question would join analysis.questions (has_many inversing).
      authorize PlantAnalysisQuestion.new(plant_analysis_id: @analysis.id)
      result = Plants::AskQuestion.new.call(analysis: @analysis, user: Current.user, params: question_params)

      if result.success?
        redirect_back_or_to plant_analysis_path(@plant, @analysis), notice: t(".success")
      else
        code, @form = result.failure
        return redirect_back_or_to(plant_analysis_path(@plant, @analysis), alert: t(".#{code}")) unless code == :invalid

        render :new, status: :unprocessable_content
      end
    end

    def ask_again
      @plant, @analysis = find_plant_and_analysis
      question = @analysis.questions.find(params[:id]).tap { |record| authorize record }
      result = Plants::AskAgain.new.call(question:)

      if result.success?
        redirect_back_or_to plant_analysis_path(@plant, @analysis), notice: t("plants.analysis_questions.create.success")
      else
        redirect_back_or_to plant_analysis_path(@plant, @analysis), alert: t("plants.analysis_questions.create.#{result.failure.first}")
      end
    end

    private

    def find_plant_and_analysis
      plant = policy_scope(Plant).find(params[:plant_id])
      [ plant, plant.analyses.find(params[:analysis_id]) ]
    end

    def question_params
      params.expect(plant_analysis_question: [ :body, :photo ])
    end
  end
end
