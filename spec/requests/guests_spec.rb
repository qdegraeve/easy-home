require "rails_helper"

# What a guest may reach (ADR 0019): the subjects and tasks opened to them, read only, and doing those tasks.
RSpec.describe "Guests", type: :request do
  let(:household) { create(:household) }
  let!(:manager) { create(:household_member, household:, role: :manager) }
  let(:guest) { create(:household_member, household:, role: :guest) }
  let(:ficus) { create(:plant, :watered, household:, name: "Ficus") }
  let(:orchid) { create(:plant, :watered, household:, name: "Orchidée") }

  before do
    Members::SetGuestAccess.new.call(member: guest, params: { subjects: [ "Plant:#{ficus.id}" ] })
    post session_path, params: { email: guest.user.email, password: "passwordpassword" }
  end

  it "shows an opened plant read only, its task sheet, and lets the guest do it" do
    get plant_path(ficus)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(edit_plant_path(ficus), new_plant_task_path(ficus))

    task = ficus.tasks.sole
    get task_path(task)
    expect(response).to have_http_status(:ok)

    post task_occurrence_completion_path(task.pending_occurrence)
    expect(task.occurrences.done.where(completed_by: guest.user)).to exist
  end

  it "finds neither another plant nor its task" do
    get plant_path(orchid)
    expect(response).to have_http_status(:not_found)

    post task_occurrence_completion_path(orchid.tasks.sole.pending_occurrence)
    expect(response).to have_http_status(:not_found)
  end

  it "changes nothing: no edit, no new task, no photo, no analysis, no new plant" do
    patch plant_path(ficus), params: { plant: { name: "Autre" } }
    expect(response).to have_http_status(:forbidden)
    get new_plant_task_path(ficus)
    expect(response).to have_http_status(:forbidden)
    get new_plant_analysis_path(ficus)
    expect(response).to have_http_status(:forbidden)
    get new_plant_path
    expect(response).to have_http_status(:forbidden)
    patch task_path(ficus.tasks.sole), params: { task: { title: "Autre" } }
    expect(response).to have_http_status(:forbidden)
    expect(ficus.reload.name).to eq("Ficus")
  end

  it "lists in the journal and on Maison only what is opened" do
    ficus.tasks.sole.occurrences.done.update_all(completed_by_id: manager.user_id)
    orchid

    get journal_path
    expect(response.body).to include("Ficus")
    expect(response.body).not_to include("Orchidée")

    get plants_path
    expect(response.body).to include("Ficus")
    expect(response.body).not_to include("Orchidée")
  end

  it "may not manage the members of the household" do
    get members_path
    expect(response).to have_http_status(:forbidden)
  end
end
