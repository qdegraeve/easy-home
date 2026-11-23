require "rails_helper"

# "Fait" on a task done when needed (Recurrence::OnDemand).
RSpec.describe "Task completions", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }
  let(:equipment) { create(:equipment, household:, name: "Lave-vaisselle") }
  let(:salt) do
    Tasks::Add.new.call(subject: equipment, params: { title: "Remettre du sel", recurrence_type: "on_demand" }).value!
  end

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  it "is never in Aujourd'hui, is done from the page of its equipment, which then says so" do
    salt
    sign_in(user)

    get root_path
    expect(response.body).not_to include("Remettre du sel")
    get equipment_path(equipment)
    expect(response.parsed_body.text.squish).to include("Remettre du sel Quand il le faut · jamais fait")

    post task_completion_path(salt), headers: { "HTTP_REFERER" => equipment_url(equipment) }

    expect(response).to redirect_to(equipment_url(equipment))
    expect(flash[:notice]).to eq("Remettre du sel noté pour « Lave-vaisselle ».")
    follow_redirect!
    expect(response.parsed_body.text.squish)
      .to include("Remettre du sel Quand il le faut · dernière fois : lun 16 nov.")
    expect(response.parsed_body.text).to include("Fait aujourd'hui")
  end

  it "is done from its sheet, which shows the last time" do
    sign_in(user)

    post task_completion_path(salt), params: { from: "sheet" }

    expect(response).to redirect_to(task_path(salt))
    follow_redirect!
    expect(response.parsed_body.text.squish)
      .to include("Quand il le faut", "Fait aujourd'hui", "Dernière fois : lun 16 nov.")
  end

  it "says why on a stale page (dated or stopped since), and answers 404 to a guest or another household" do
    dated = Tasks::Add.new.call(subject: equipment, params: { title: "Filtre", due_on: "2026-11-16" }).value!
    sign_in(user)
    post task_completion_path(dated)
    expect(flash[:notice]).to eq("Cette tâche a une date : faites-la depuis sa ligne.")
    salt.update!(active: false)
    post task_completion_path(salt)
    expect(flash[:notice]).to eq("Cette tâche est arrêtée.")

    sign_in(create(:household_member, household:, role: :guest).user)
    post task_completion_path(salt)
    expect(response).to have_http_status(:not_found)

    sign_in(create(:user, :with_household))
    post task_completion_path(salt)
    expect(response).to have_http_status(:not_found)
    expect(salt.occurrences).to be_empty
  end

  it "creates a task done when needed without a date, ignoring a reminder and the importance sent for it" do
    sign_in(user)

    post equipment_tasks_path(equipment), params: {
      task: {
        title: "Liquide de rinçage",
        recurrence_type: "on_demand",
        due_on: "",
        reminder_time: "19:00",
        critical: "1"
      }
    }

    task = equipment.tasks.sole
    expect(task).to have_attributes(recurrence_type: "on_demand", reminder_minute: nil, importance: "flexible")
    expect(task.occurrences).to be_empty
  end

  it "undoes a completion from its toast without opening a due date" do
    sign_in(user)
    post task_completion_path(salt)
    done = salt.occurrences.done.sole

    delete task_occurrences_batch_completion_path, params: { occurrence_ids: [ done.id ] }

    expect(salt.occurrences).to be_empty
  end

  it "offers no Fait on the sheet of a stopped task done when needed" do
    salt.update!(active: false)
    sign_in(user)

    get task_path(salt)

    expect(response.body).not_to include(task_completion_path(salt))
  end
end
