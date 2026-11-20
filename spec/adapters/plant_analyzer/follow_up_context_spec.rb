require "rails_helper"

RSpec.describe PlantAnalyzer::FollowUpContext do
  let(:plant) { create(:plant, :watered, name: "Citronnier") }
  let(:analysis_photo) { create(:photo, plant:, taken_at: Time.zone.parse("2026-11-12 09:00")) }
  let(:analysis) do
    create(:plant_analysis, :with_proposals, plant:, photos: [ analysis_photo ], observations: "Feuilles jaunes.",
                                             created_at: Time.zone.parse("2026-11-12 10:00"))
  end

  it "sends the analysis, the conversation so far and the new question, with the photos numbered in order" do
    first_photo = create(:photo, plant:, taken_at: Time.zone.parse("2026-11-14 09:00"))
    create(:plant_analysis_question, :done, analysis:, body: "Et ces taches ?", photo: first_photo,
                                            answer: "Un peu de soleil en trop.")
    question = create(:plant_analysis_question, analysis:, body: "Faut-il le déplacer ?")
    create(:plant_analysis_question, analysis:, body: "Later question", status: :failed)

    context = described_class.new(question, today: Date.new(2026, 11, 16))

    expect(context.photos).to eq([ analysis_photo, first_photo ])
    expect(context.to_text).to include(
      "Plant: Citronnier.",
      "Photos, oldest first: photo 1 on 2026-11-12.",
      "Your analysis of 2026-11-12:",
      "Health: ok.",
      "Species: Citrus limon (Citronnier), confidence high.",
      "Suggested watering: every 4 days.",
      "Observations: Feuilles jaunes.",
      "Action in 3 days: Pailler le pied. Garde la terre fraîche.",
      "Owner (with photo 2, taken on 2026-11-14): Et ces taches ?",
      "You: Un peu de soleil en trop.",
      "New question from the owner: Faut-il le déplacer ?"
    )
    expect(context.to_text).not_to include("Later question")
  end

  it "numbers the photo attached to the new question after the others" do
    photo = create(:photo, plant:, taken_at: Time.zone.parse("2026-11-15 09:00"))
    question = create(:plant_analysis_question, analysis:, body: "Et maintenant ?", photo:)

    context = described_class.new(question)

    expect(context.photos).to eq([ analysis_photo, photo ])
    expect(context.to_text).to include("No previous question.")
    expect(context.to_text)
      .to end_with("New question from the owner (with photo 2, taken on 2026-11-15): Et maintenant ?")
  end
end
