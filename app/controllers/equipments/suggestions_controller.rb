module Equipments
  # The screen after adding an equipment (design, "Ajouter un équipement"): its suggested upkeep tasks, unchecked, each
  # with its rhythm and first date; the checked ones are added at once (Tasks::AddSuggestions), or none ("Plus tard").
  class SuggestionsController < ApplicationController
    def new
      @equipment = find_equipment
      @suggestions = available_suggestions
      redirect_to @equipment if @suggestions.empty?
    end

    def create
      @equipment = find_equipment
      result = Tasks::AddSuggestions.new.call(subject: @equipment, keys: params[:keys])

      if result.success?
        redirect_to @equipment, notice: t(".success", count: result.value!.size)
      else
        @suggestions = available_suggestions
        return redirect_to(@equipment) if @suggestions.empty? # all added meanwhile, by another member

        flash.now[:alert] = t(".#{result.failure.first}")
        render :new, status: :unprocessable_content
      end
    end

    private

    def find_equipment
      # The same right as "Ajouter une tâche" on its page (TasksController).
      policy_scope(Equipment).find(params[:equipment_id]).tap do |equipment|
        authorize Task.new(household: equipment.household, subject: equipment), :create?
      end
    end

    def available_suggestions
      Catalogue.suggestions_for(@equipment, existing_keys: @equipment.tasks.used_suggestion_keys)
    end
  end
end
