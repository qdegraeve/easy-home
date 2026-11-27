require "rails_helper"

# Photos of an equipment and of a task (ADR 0016).
RSpec.describe "Subject photos", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }
  let(:equipment) { create(:equipment, household:, name: "Clim") }
  let(:task) { Tasks::Add.new.call(subject: equipment, params: { title: "Filtre", due_on: "2026-11-16" }).value! }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "passwordpassword" }
  end

  def picture(name = "plant.png")
    Rack::Test::UploadedFile.new(file_fixture(name))
  end

  it "adds a photo to an equipment, shows it as its face and in its Photos tab, then deletes it" do
    sign_in(user)

    post equipment_photos_path(equipment), params: { photo: { file: picture } }

    photo = equipment.photos.sole
    expect(response).to redirect_to(equipment_path(equipment, tab: "photos"))
    get equipment_path(equipment)
    expect(response.body).to include(equipment_photo_path(equipment, photo))
    get equipment_path(equipment, tab: "photos")
    expect(response.parsed_body.css("img[loading=lazy]").size).to eq(1)
    get equipment_photo_path(equipment, photo)
    expect(response.parsed_body.text.squish).to include("Photo du 16 novembre 2026")

    delete equipment_photo_path(equipment, photo)
    expect(response).to redirect_to(equipment_path(equipment, tab: "photos"))
    expect(Photo.count).to eq(0)
  end

  it "adds a photo to a task, shown in its sheet with how to do it" do
    sign_in(user)

    post task_photos_path(task), params: { photo: { file: picture } }

    expect(response).to redirect_to(task_path(task))
    follow_redirect!
    expect(response.body).to include(task_photo_path(task, task.photos.sole))
  end

  it "refuses a file that is not a picture, and a photo of a stopped task" do
    sign_in(user)

    post equipment_photos_path(equipment), params: { photo: { file: picture("not_an_image.jpg") } }
    expect(flash[:alert]).to include("n'est pas une image")

    task.update!(active: false)
    post task_photos_path(task), params: { photo: { file: picture } }
    expect(response).to have_http_status(:forbidden)
    expect(Photo.count).to eq(0)
  end

  it "never shows nor deletes a photo through another subject's URL" do
    other = create(:equipment, household:)
    photo = Photos::Add.new.call(subject: equipment, file: picture).value!
    sign_in(user)

    get equipment_photo_path(other, photo)
    expect(response).to have_http_status(:not_found)
    delete task_photo_path(task, photo)
    expect(response).to have_http_status(:not_found)
    expect(Photo.exists?(photo.id)).to be(true)
  end

  {
    "a guest of the household" => ->(household) { create(:household_member, household:, role: :guest).user },
    "a user of another household" => ->(_household) { create(:user, :with_household) }
  }.each do |label, intruder|
    it "answers 404 to #{label}, adding, showing and deleting nothing" do
      photo = Photos::Add.new.call(subject: equipment, file: picture).value!
      task_photo = Photos::Add.new.call(subject: task, file: picture).value!
      sign_in(instance_exec(household, &intruder))

      post equipment_photos_path(equipment), params: { photo: { file: picture } }
      expect(response).to have_http_status(:not_found)
      get equipment_photo_path(equipment, photo)
      expect(response).to have_http_status(:not_found)
      delete task_photo_path(task, task_photo)
      expect(response).to have_http_status(:not_found)
      expect(Photo.count).to eq(2)
    end
  end
end
