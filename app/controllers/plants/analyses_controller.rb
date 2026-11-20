module Plants
  # AI analyses of a plant (ADR 0008).
  class AnalysesController < ApplicationController
    def new
      @plant = find_plant
      authorize PlantAnalysis.new(plant: @plant)
      @request = AnalysisRequest.new(plant: @plant, photo_ids: @plant.photos.limit(1).ids)
    end

    def create
      @plant = find_plant
      authorize PlantAnalysis.new(plant: @plant)
      result = Plants::RequestAnalysis.new.call(plant: @plant, user: Current.user, params: analysis_params)

      if result.success?
        redirect_to @plant, notice: t(".success")
      else
        code, @request = result.failure
        return redirect_to(@plant, alert: t(".#{code}")) unless code == :invalid

        render :new, status: :unprocessable_content
      end
    end

    def show
      @plant = find_plant
      @analysis = @plant.analyses.find(params[:id]).tap { |analysis| authorize analysis }
    end

    private

    def find_plant
      policy_scope(Plant).find(params[:plant_id])
    end

    # Optional: without it, the latest photo is analysed. Anything but a hash is a malformed request (400).
    def analysis_params
      value = params.fetch(:plant_analysis, ActionController::Parameters.new)
      raise ActionController::BadRequest unless value.is_a?(ActionController::Parameters)

      value.permit(:note, photo_ids: [])
    end
  end
end
