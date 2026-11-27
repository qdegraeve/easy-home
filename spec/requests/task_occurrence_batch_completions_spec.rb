require "rails_helper"

RSpec.describe "Batch completions", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  before { post session_path, params: { email: user.email, password: "passwordpassword" } }

  def due_watering(name, household: self.household)
    plant = create(
      :plant,
      :watered,
      household:,
      name:,
      interval_days: 3,
      last_watered_at: Time.zone.parse("2026-11-12 08:00")
    )
    plant.watering_task.pending_occurrence
  end

  def done_watering(name, household: self.household)
    Tasks::Complete.new.call(occurrence: due_watering(name, household:), user: create(:user)).value!
  end

  it "waters several plants at once, then offers to undo it" do
    lemon, basil = due_watering("Citronnier"), due_watering("Basilic")

    post task_occurrences_batch_completion_path, params: { occurrence_ids: [ lemon.id, basil.id ] }

    expect(response).to redirect_to(root_path)
    expect([ lemon.reload, basil.reload ].map(&:status)).to eq(%w[done done])
    expect(flash[:notice]).to eq("2 arrosages notés.")
    expect(flash[:undo_ids]).to contain_exactly(lemon.id, basil.id)

    delete task_occurrences_batch_completion_path, params: { occurrence_ids: [ lemon.id, basil.id ] }

    expect(TaskOccurrence.where(id: [ lemon.id, basil.id ])).to be_empty
    expect(flash[:notice]).to eq("2 annulés, prochaines échéances recalculées.")
  end

  it "ignores the occurrences of another household" do
    other = due_watering("Voisin", household: create(:household))

    post task_occurrences_batch_completion_path, params: { occurrence_ids: [ other.id ] }

    expect(other.reload).to be_pending
    expect(response).to redirect_to(today_watering_path)
    expect(flash[:notice]).to eq("Aucun arrosage coché.")
  end

  it "does not undo the completions of another household" do
    other = done_watering("Voisin", household: create(:household))

    delete task_occurrences_batch_completion_path, params: { occurrence_ids: [ other.id ] }

    expect(other.reload).to be_done
    expect(flash[:notice]).to eq("Rien à annuler.")
  end

  it "does not let a guest do the tasks" do
    guest = create(:household_member, household:, role: :guest).user
    post session_path, params: { email: guest.email, password: "passwordpassword" }
    lemon = due_watering("Citronnier")

    post task_occurrences_batch_completion_path, params: { occurrence_ids: [ lemon.id ] }
    expect(lemon.reload).to be_pending

    done = done_watering("Basilic")
    delete task_occurrences_batch_completion_path, params: { occurrence_ids: [ done.id ] }
    expect(done.reload).to be_done
  end
end
