module Plants
  class ArchivesController < ApplicationController
    def create
      plant = find_plant(:archive?)
      Plants::Archive.new.call(plant:)
      redirect_to plant, notice: t(".success", name: plant.name), status: :see_other
    end

    def destroy
      plant = find_plant(:restore?)
      Plants::Restore.new.call(plant:)
      redirect_to plant, notice: t(".success", name: plant.name), status: :see_other
    end

    private

    def find_plant(action)
      policy_scope(Plant).find(params[:plant_id]).tap { |plant| authorize plant, action }
    end
  end
end
