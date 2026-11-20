require "rails_helper"

RSpec.describe "Plant photos", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }
  let(:plant) { create(:plant, :watered, household:, name: "Citronnier") }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  def picture(name = "plant.png")
    Rack::Test::UploadedFile.new(file_fixture(name))
  end

  def add_photo
    Photos::Add.new.call(plant:, file: picture).value!
  end

  it "adds a photo and shows it on the plant page" do
    sign_in(user)

    post plant_photos_path(plant), params: { photo: { file: picture } }

    expect(response).to redirect_to(plant_path(plant))
    follow_redirect!
    expect(response.body).to include("Photo ajoutée.", "Photo du ")
    expect(plant.photos.count).to eq(1)
  end

  it "explains why a file is refused" do
    sign_in(user)

    post plant_photos_path(plant), params: { photo: { file: picture("not_an_image.jpg") } }

    expect(response).to redirect_to(plant_path(plant))
    expect(flash[:alert]).to eq("Photo n'est pas une image JPEG, PNG ou WebP lisible")
    expect(plant.photos).to be_empty
  end

  it "re-renders the new plant form when its photo is refused" do
    sign_in(user)

    post plants_path,
      params: { plant: { name: "Basilic", watering_interval_days: "2", photo: picture("not_an_image.jpg") } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Photo n&#39;est pas une image JPEG, PNG ou WebP lisible")
    expect(Plant.where(name: "Basilic")).to be_empty
  end

  it "answers 400 or a validation error to malformed parameters, never 500" do
    sign_in(user)

    post plant_photos_path(plant), params: { photo: "abc" }
    expect(response).to have_http_status(:bad_request)

    post plant_photos_path(plant), params: { photo: { file: "abc" } }
    expect(flash[:alert]).to eq("Photo n'est pas une image JPEG, PNG ou WebP lisible")

    post plants_path, params: { plant: { name: "Basilic", watering_interval_days: "2", photo: "abc" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "hides the photo form on an archived plant" do
    plant.update!(archived_at: Time.current)
    sign_in(user)

    get plant_path(plant)

    expect(response.body).not_to include("Nouvelle photo")
  end

  it "shows a photo in large, then deletes it" do
    photo = add_photo
    sign_in(user)

    get plant_photo_path(plant, photo)
    expect(response.body).to include("Photo du 16 novembre 2026", "Supprimer la photo")

    delete plant_photo_path(plant, photo)
    expect(response).to redirect_to(plant_path(plant))
    expect(Photo.exists?(photo.id)).to be(false)
  end

  it "forbids adding a photo to an archived plant" do
    plant.update!(archived_at: Time.current)
    sign_in(user)

    post plant_photos_path(plant), params: { photo: { file: picture } }

    expect(response).to have_http_status(:forbidden)
    expect(plant.photos).to be_empty
  end

  it "does not find the photo of another plant through this plant's URL" do
    photo = add_photo
    other_plant = create(:plant, :watered, household:)
    sign_in(user)

    get plant_photo_path(other_plant, photo)

    expect(response).to have_http_status(:not_found)
  end

  describe "access denied" do
    {
      "a guest of the household" => -> { create(:household_member, household:, role: :guest).user },
      "a user of another household" => -> { create(:user, :with_household) }
    }.each do |intruder_label, intruder|
      it "answers 404 to #{intruder_label} on create" do
        sign_in(instance_exec(&intruder))

        post plant_photos_path(plant), params: { photo: { file: picture } }

        expect(response).to have_http_status(:not_found)
        expect(plant.photos).to be_empty
      end

      it "answers 404 to #{intruder_label} on show and destroy" do
        photo = add_photo
        sign_in(instance_exec(&intruder))

        get plant_photo_path(plant, photo)
        expect(response).to have_http_status(:not_found)
        delete plant_photo_path(plant, photo)
        expect(response).to have_http_status(:not_found)
        expect(Photo.exists?(photo.id)).to be(true)
      end
    end
  end
end
