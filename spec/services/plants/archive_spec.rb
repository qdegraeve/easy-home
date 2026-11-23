require "rails_helper"

RSpec.describe "Plant archiving" do
  include ActiveSupport::Testing::TimeHelpers

  let(:plant) { create(:plant, :watered, interval_days: 3, last_watered_at: Time.zone.parse("2026-11-01 08:00")) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  describe Plants::Archive do
    it "stops reminders and keeps the log" do
      result = described_class.new.call(plant:)

      expect(result).to be_success
      expect(plant.reload).to be_archived
      task = plant.watering_task
      expect(task).not_to be_active
      expect(task.pending_occurrence).to be_nil
      expect(task.occurrences.done.count).to eq(1)
    end

    it "rejects an already archived plant" do
      described_class.new.call(plant:)

      expect(described_class.new.call(plant:).failure.first).to eq(:already_archived)
    end
  end

  describe Plants::Restore do
    it "resumes watering, recomputed from the last watering, late but within its tolerance (not missed at once)" do
      Plants::Archive.new.call(plant:)

      result = described_class.new.call(plant: plant.reload)

      expect(result).to be_success
      expect(plant.reload).not_to be_archived
      task = plant.watering_task
      expect(task).to be_active
      # Due on the 4th, every 3 days with 1 day of tolerance: on the 15th.
      expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-15 00:00"))
      expect(Tasks::MarkMissed.new.call.value!).to eq(0)
    end

    it "resumes other tasks too: the repeating one restarts, the done one-off stays finished" do
      engrais = Tasks::Add.new.call(
        subject: plant,
        params: { title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-20", interval: "14", unit: "days" }
      ).value!
      taille = Tasks::Add.new.call(subject: plant, params: { title: "Tailler", due_on: "2026-11-16" }).value!
      Tasks::Complete.new.call(occurrence: taille.pending_occurrence, user: create(:user))
      Plants::Archive.new.call(plant:)
      expect(engrais.reload.pending_occurrence).to be_nil

      described_class.new.call(plant: plant.reload)

      expect(engrais.reload.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-20 00:00"))
      expect(taille.reload.pending_occurrence).to be_nil
    end

    it "rejects a plant that is not archived" do
      expect(described_class.new.call(plant:).failure.first).to eq(:not_archived)
    end
  end
end
