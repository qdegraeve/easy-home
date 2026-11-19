require "rails_helper"

RSpec.describe "Archivage d'une plante" do
  include ActiveSupport::Testing::TimeHelpers

  let(:plant) { create(:plant, :watered, interval_days: 3, last_watered_at: Time.zone.parse("2026-11-01 08:00")) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  describe Plants::Archive do
    it "arrête les rappels et garde le journal" do
      result = described_class.new.call(plant:)

      expect(result).to be_success
      expect(plant.reload).to be_archived
      task = plant.watering_task
      expect(task).not_to be_active
      expect(task.pending_occurrence).to be_nil
      expect(task.occurrences.done.count).to eq(1)
    end

    it "refuse une plante déjà archivée" do
      described_class.new.call(plant:)

      expect(described_class.new.call(plant:).failure.first).to eq(:already_archived)
    end
  end

  describe Plants::Restore do
    it "reprend l'arrosage, échéance recalculée depuis le dernier arrosage (ici en retard)" do
      Plants::Archive.new.call(plant:)

      result = described_class.new.call(plant: plant.reload)

      expect(result).to be_success
      expect(plant.reload).not_to be_archived
      task = plant.watering_task
      expect(task).to be_active
      expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-04 00:00"))
    end

    it "reprend aussi les autres tâches : la répétée repart, l'unique déjà faite reste finie" do
      engrais = Tasks::Add.new.call(
        subject: plant,
        params: { title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-20", interval_days: "14" }
      ).value!
      taille = Tasks::Add.new.call(subject: plant, params: { title: "Tailler", due_on: "2026-11-16" }).value!
      Tasks::Complete.new.call(occurrence: taille.pending_occurrence, user: create(:user))
      Plants::Archive.new.call(plant:)
      expect(engrais.reload.pending_occurrence).to be_nil

      described_class.new.call(plant: plant.reload)

      expect(engrais.reload.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-20 00:00"))
      expect(taille.reload.pending_occurrence).to be_nil
    end

    it "refuse une plante non archivée" do
      expect(described_class.new.call(plant:).failure.first).to eq(:not_archived)
    end
  end
end
