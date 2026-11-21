module Plants
  # AI analyses of a plant (ADR 0008).
  class AnalysesController < ApplicationController
    def new
      @plant = find_plant
      authorize PlantAnalysis.new(plant: @plant)
      # `note`: prefilled when the analysis is restarted after a change of place.
      @request = AnalysisRequest.new(plant: @plant, photo_ids: @plant.photos.limit(1).ids, note: params[:note])
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

    def accept_species
      analysis = find_analysis_to_accept
      respond_to_acceptance(Plants::AcceptSpecies.new.call(analysis:), species: analysis.species_name)
    end

    def accept_watering
      analysis = find_analysis_to_accept
      respond_to_acceptance(Plants::AcceptWatering.new.call(analysis:), count: analysis.watering_interval_days)
    end

    def accept_action
      analysis = find_analysis_to_accept
      result = Plants::AcceptAction.new.call(analysis:, index: params[:index].to_i)
      respond_to_acceptance(result, title: result.value_or(nil)&.title)
    end

    private

    def find_analysis_to_accept
      @plant = find_plant
      @plant.analyses.find(params[:id]).tap { |analysis| authorize analysis, :accept? }
    end

    # Back to the page of the button: the plant, or the analysis page.
    def respond_to_acceptance(result, **values)
      if result.success?
        redirect_back_or_to @plant, notice: t(".success", **values)
      else
        redirect_back_or_to @plant, alert: t("plants.analyses.accept.#{result.failure.first}")
      end
    end

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
