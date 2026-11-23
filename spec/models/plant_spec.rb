require "rails_helper"

RSpec.describe Plant, type: :model do
  include ActiveJob::TestHelper

  it_behaves_like "a photo subject" do
    subject { create(:plant) }
  end

  it "is deleted with its photos, its cover, its analyses and the photo of a question" do
    plant = create(:plant)
    cover = create(:photo, plant:)
    question_photo = create(:photo, plant:)
    plant.update!(cover_photo: cover)
    analysis = create(:plant_analysis, plant:, photos: [ cover ])
    analysis.questions.create!(body: "Et la tache ?", photo: question_photo, asked_by: create(:user))

    plant.destroy!

    counts = [ Photo, PlantAnalysis, PlantAnalysisPhoto, PlantAnalysisQuestion ].map(&:count)
    expect(counts).to eq([ 0, 0, 0, 0 ])
  end

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_length_of(:name).is_at_most(100) }

  it "rejects a location of another household" do
    plant = build(:plant, location: create(:location))

    expect(plant).not_to be_valid
    expect(plant.errors[:location]).to be_present
  end

  it "never changes household" do
    plant = create(:plant)

    expect { plant.update(household: create(:household)) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  it "deletes its tasks and their history with it" do
    plant = create(:plant, :watered)

    expect { plant.destroy! }.to change(Task, :count).by(-1).and change(TaskOccurrence, :count).by(-2)
  end

  it "loses its location when the location is deleted" do
    location = create(:location)
    plant = create(:plant, household: location.household, location:)

    location.destroy!

    expect(plant.reload.location).to be_nil
  end

  describe "#place_change_since_analysis" do
    let(:household) { create(:household) }
    let(:shade) { create(:location, household:, exposure: :partial_shade, sheltered: true) }
    let(:sun) { create(:location, household:, exposure: :full_sun) }
    let(:plant) { create(:plant, household:, location: shade) }

    it "is nil while the plant stays in the conditions of its last analysis, even in a renamed location" do
      create(:plant_analysis, :done, plant:, place: plant.place)
      shade.update!(name: "Sous l'auvent")

      expect(plant.reload.place_change_since_analysis).to be_nil
    end

    it "gives the former and the current place when the plant moved, and clears once it is back" do
      create(:plant_analysis, :done, plant:, place: plant.place)

      plant.update!(location: sun)
      expect(plant.reload.place_change_since_analysis).to eq([
        { "exposure" => "partial_shade", "sheltered" => true },
        { "exposure" => "full_sun", "sheltered" => false }
      ])

      plant.update!(location: shade)
      expect(plant.reload.place_change_since_analysis).to be_nil
    end

    it "follows a change of the location itself, and a plant taken out of any location" do
      create(:plant_analysis, :done, plant:, place: plant.place)

      shade.update!(sheltered: false)
      expect(plant.reload.place_change_since_analysis.last)
        .to eq({ "exposure" => "partial_shade", "sheltered" => false })

      plant.update!(location: nil)
      expect(plant.reload.place_change_since_analysis.last).to eq({ "exposure" => nil, "sheltered" => false })
    end

    it "is cleared by a newer finished analysis made in the new place" do
      create(:plant_analysis, :done, plant:, place: plant.place, created_at: 2.days.ago)
      plant.update!(location: sun)
      create(:plant_analysis, :done, plant:, place: plant.place)

      expect(plant.reload.place_change_since_analysis).to be_nil
    end

    it "is nil for an analysis made before places were recorded, and looks at the last finished analysis only" do
      create(:plant_analysis, :done, plant:, place: nil)
      expect(plant.place_change_since_analysis).to be_nil

      create(:plant_analysis, :done, plant:, place: { "exposure" => "shade", "sheltered" => false })
      create(:plant_analysis, plant:, place: plant.place) # pending
      expect(plant.reload.place_change_since_analysis.first).to eq({ "exposure" => "shade", "sheltered" => false })
    end
  end

  describe "cover photo" do
    it "must be one of the plant's photos" do
      plant = create(:plant)
      other = create(:photo)

      plant.cover_photo = other

      expect(plant).not_to be_valid
      expect(plant.errors[:cover_photo]).to be_present
    end
  end
end
