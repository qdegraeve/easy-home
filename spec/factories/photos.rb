FactoryBot.define do
  factory :photo do
    plant
    subject { plant }
    taken_at { Time.current }
    image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/plant.png")) }
  end
end
