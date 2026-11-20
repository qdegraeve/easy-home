module Plants
  # Photo follow-up of a plant.
  class PhotosController < ApplicationController
    def create
      plant = find_plant
      authorize Photo.new(plant:)
      result = Photos::Add.new.call(plant:, file: params.expect(photo: [ :file ])[:file])

      if result.success?
        redirect_to plant, notice: t(".success")
      else
        code, upload = result.failure
        alert = code == :invalid ? upload.errors.full_messages.to_sentence : t(".#{code}")
        redirect_to plant, alert:
      end
    end

    def show
      @plant = find_plant
      @photo = find_photo(@plant)
    end

    def update
      @plant = find_plant
      @photo = find_photo(@plant)

      if @photo.update(params.expect(photo: [ :taken_on ]))
        redirect_to plant_photo_path(@plant, @photo), notice: t(".success")
      else
        render :show, status: :unprocessable_content
      end
    end

    def destroy
      plant = find_plant
      find_photo(plant).destroy!
      redirect_to plant, notice: t(".success"), status: :see_other
    end

    private

    def find_plant
      policy_scope(Plant).find(params[:plant_id])
    end

    def find_photo(plant)
      plant.photos.find(params[:id]).tap { |photo| authorize photo }
    end
  end
end
