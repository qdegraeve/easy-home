module Plants
  # Chooses the photo shown as the face of the plant (its page header, its lists).
  class CoversController < ApplicationController
    def create
      plant = policy_scope(Plant).find(params[:plant_id])
      photo = plant.photos.find(params[:photo_id]).tap { |record| authorize record, :update? }

      plant.update!(cover_photo: photo)
      redirect_to plant_photo_path(plant, photo), notice: t(".success"), status: :see_other
    end
  end
end
