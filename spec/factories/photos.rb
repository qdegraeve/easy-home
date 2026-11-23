FactoryBot.define do
  factory :photo do
    transient { plant { association :plant } } # the subject of most photos
    subject { plant }
    taken_at { Time.current }
    image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/plant.png")) }
  end
end
