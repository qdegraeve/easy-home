module Plants
  # Photo follow-up of a plant.
  class PhotosController < ApplicationController
    def create
      plant = find_plant
      authorize Photo.new(plant:)
      result = Photos::Add.new.call(plant:, file: params.expect(photo: [ :file ])[:file])

      if result.success?
        redirect_to plant_path(plant, tab: "photos"), notice: t(".success")
      else
        code, upload = result.failure
        alert = code == :invalid ? upload.errors.full_messages.to_sentence : t(".#{code}")
        redirect_to plant_path(plant, tab: "photos"), alert:
      end
    end

    # All the photos of the plant, the oldest first (left is the past): the viewer scrolls through them.
    def show
      @plant = find_plant
      @photo = find_photo(@plant)
      @photos = @plant.photos.with_attached_image.to_a.reverse
      @index = @photos.index(@photo)
      find_neighbours
    end

    # The date of the photo, on its own page (a native modal in the Android app, like every /edit page).
    def edit
      @plant = find_plant
      @photo = find_photo(@plant)
    end

    def update
      @plant = find_plant
      @photo = find_photo(@plant)

      if @photo.update(params.expect(photo: [ :taken_at ]))
        redirect_to plant_photo_path(@plant, @photo), notice: t(".success")
      else
        render :edit, status: :unprocessable_content
      end
    end

    # Back to the next photo, as in a gallery (the newer one, else the older one), or to the photos when none is left.
    def destroy
      @plant = find_plant
      @photo = find_photo(@plant)
      find_neighbours
      @photo.destroy!
      next_photo = @newer || @older
      redirect_to next_photo ? plant_photo_path(@plant, next_photo) : plant_path(@plant, tab: "photos"),
        notice: t(".success"), status: :see_other
    end

    private

    def find_plant
      policy_scope(Plant).find(params[:plant_id])
    end

    # The plant's photos are newest first: "previous" is the older one, "next" the newer one, to follow its growth.
    def find_neighbours
      photos = @plant.photos.to_a
      index = photos.index(@photo)
      @older = photos[index + 1]
      @newer = index.positive? ? photos[index - 1] : nil
    end

    def find_photo(plant)
      plant.photos.find(params[:id]).tap { |photo| authorize photo }
    end
  end
end
