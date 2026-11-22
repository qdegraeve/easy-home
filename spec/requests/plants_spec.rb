require "rails_helper"

RSpec.describe "Plants", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household, name: "Maison") }
  let(:user) { create(:household_member, household:, role: :member).user }
  let(:guest) { create(:household_member, household:, role: :guest).user }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  def watering_button
    Nokogiri::HTML(response.body).at_css(%(button[aria-label="J'ai arrosé : Basilic"]))
  end

  describe "GET / and GET /plants" do
    it "lists what to do today on the home page, and the plants by location, archived ones apart, in Plantes" do
      terrasse = create(:location, household:, name: "Terrasse", exposure: :partial_shade)
      create(:plant, :watered, household:, name: "Basilic", location: terrasse, interval_days: 1,
                               last_watered_at: Time.zone.parse("2026-11-15 08:00"))
      create(:plant, :watered, household:, name: "Aloe", interval_days: 9, last_watered_at: Time.current)
      create(:plant, :watered, household:, name: "Fougère morte", archived_at: Time.current)
      sign_in(user)

      get root_path

      expect(response.body).to include("À faire aujourd&#39;hui · 1", "J&#39;ai arrosé : Basilic")
      expect(response.body).not_to include("J&#39;ai arrosé : Aloe")

      get plants_path

      text = response.parsed_body.text.squish
      expect(text).to include("2 plantes", "Terrasse · Mi-ombre", "Sans emplacement", "dans 9 j")
      expect(response.body).to include("Plantes archivées · 1", "Fougère morte")
    end

    it "shows neither plants nor the add button to a guest" do
      create(:plant, :watered, household:, name: "Basilic")
      sign_in(guest)

      get root_path
      expect(response.body).not_to include("Basilic", "Ajouter une plante")

      get plants_path
      expect(response.body).not_to include("Ajouter une plante")
    end
  end

  describe "GET /plants/new" do
    it "asks for the photo first and a few fields, the watering prefilled, the rest folded" do
      sign_in(user)

      get new_plant_path

      page = response.parsed_body
      labels = page.css("form label").map { |label| label.text.squish }
      expect(labels.first(4)).to eq([ "Photo", "Nom", "Emplacement", "Arrosage" ])
      expect(page.at_css("input[name='plant[watering_interval_days]']")["value"]).to eq("7")
      expect(page.at_css("details summary").text).to include("Plus de détails")
      expect(page.at_css("details input[name='plant[species]']")).to be_present
    end
  end

  describe "POST /plants refused" do
    it "opens the folded details again when one of their fields is refused, and only then" do
      sign_in(user)

      post plants_path, params: { plant: { name: "Basilic", watering_interval_days: "2", species: "x" * 101 } }
      expect(response.parsed_body.at_css("details[open] input[name='plant[species]']")).to be_present

      post plants_path, params: { plant: { name: "", watering_interval_days: "2" } }
      expect(response.parsed_body.at_css("details")["open"]).to be_nil
    end

    it "asks to choose the photo again, which a browser never keeps" do
      sign_in(user)

      post plants_path, params: { plant: { name: "", watering_interval_days: "2",
                                           photo: fixture_file_upload("plant.png", "image/png") } }

      expect(response.body).to include("Choisissez la photo à nouveau")
      expect(household.plants).to be_empty
    end
  end

  describe "POST /plants" do
    it "adds a plant to the current household" do
      sign_in(user)

      post plants_path,
        params: { plant: { name: "Basilic", watering_interval_days: "2", last_watered_on: "2026-11-16" } }

      plant = household.plants.sole
      expect(response).to redirect_to(plant_path(plant))
      expect(plant.watering_task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-18 00:00"))
    end

    it "renders the form again on an invalid interval" do
      sign_in(user)

      post plants_path, params: { plant: { name: "Basilic", watering_interval_days: "0" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Arrosage doit être dans l&#39;intervalle 1..60")
      expect(Plant.count).to eq(0)
    end

    it "rejects a guest" do
      sign_in(guest)

      post plants_path, params: { plant: { name: "Basilic", watering_interval_days: "2" } }

      expect(response).to have_http_status(:forbidden)
      expect(Plant.count).to eq(0)
    end
  end

  describe "GET /plants/:id" do
    it "shows the watering and the log" do
      plant = create(:plant, :watered, household:, name: "Basilic", interval_days: 2,
                                       last_watered_at: Time.zone.parse("2026-11-15 08:00"))
      sign_in(user)

      get plant_path(plant)

      expect(response.body).to include("Tous les 2 jours", "Prochain arrosage :", "demain")
      expect(response.body).to include("Dernier arrosage : dim 15 nov.")
    end

    it "offers \"J'ai arrosé\" as the main button when due or late, as a secondary one before" do
      plant = create(:plant, :watered, household:, name: "Basilic", interval_days: 2,
                                       last_watered_at: Time.zone.parse("2026-11-15 08:00"))
      sign_in(user)

      get plant_path(plant)
      expect(watering_button["class"]).to include("bg-action-soft")

      plant.watering_task.pending_occurrence.update!(due_at: Time.zone.parse("2026-11-16 00:00"))
      get plant_path(plant)
      expect(watering_button["class"]).not_to include("bg-action-soft")
      expect(watering_button.text).to include("J'ai arrosé")

      plant.watering_task.pending_occurrence.update!(due_at: Time.zone.parse("2026-11-15 00:00"))
      get plant_path(plant)
      expect(watering_button["class"]).not_to include("bg-action-soft")
    end

    it "tells in the history what the rain did: a watering, then a watering moved by a day" do
      plant = create(:plant, :watered, household:, name: "Basilic", interval_days: 2,
                                       last_watered_at: Time.zone.parse("2026-11-14 08:00"))
      Tasks::Complete.new.call(occurrence: plant.watering_task.pending_occurrence, user: nil, source: :rain)
      travel 2.days
      Tasks::Postpone.new.call(occurrence: plant.watering_task.reload.pending_occurrence, user: nil, source: :rain)
      sign_in(user)

      get plant_path(plant, tab: "history")

      text = response.parsed_body.text.squish
      expect(text).to include(
        "Arrosé par la pluie lun 16 nov.",
        "Arrosage : échéance reportée par la pluie mer 18 nov."
      )
      # The rain cloud icon on the watering by the rain, in the history.
      expect(response.parsed_body.at_css("section[aria-labelledby=journal]").to_html.scan("M4 14.899").size).to eq(1)
    end

    it "says on the watering card why the date moved, and that the last watering was the rain's" do
      plant = create(:plant, :watered, household:, name: "Basilic", interval_days: 2,
                                       last_watered_at: Time.zone.parse("2026-11-14 08:00"))
      Tasks::Complete.new.call(occurrence: plant.watering_task.pending_occurrence, user: nil, source: :rain)
      sign_in(user)

      get plant_path(plant)
      text = response.parsed_body.text.squish
      expect(text).to include("Dernier arrosage : lun 16 nov., par la pluie")
      expect(text).not_to include("Reporté par la pluie")

      travel 2.days
      Tasks::Postpone.new.call(occurrence: plant.watering_task.reload.pending_occurrence, user: nil, source: :rain)
      get plant_path(plant)
      card = response.parsed_body.at_css("section[aria-labelledby=watering]").text.squish
      expect(card).to include("Prochain arrosage : demain", "Reporté par la pluie")

      Tasks::Complete.new.call(occurrence: plant.watering_task.reload.pending_occurrence, user:)
      get plant_path(plant)
      card = response.parsed_body.at_css("section[aria-labelledby=watering]").text.squish
      expect(card).to include("Dernier arrosage : mer 18 nov.")
      expect(card).not_to include("par la pluie")
    end

    it "no longer says the rain moved the watering once it was missed since" do
      plant = create(:plant, :watered, household:, name: "Basilic", interval_days: 2,
                                       last_watered_at: Time.zone.parse("2026-11-14 08:00"))
      Tasks::Postpone.new.call(occurrence: plant.watering_task.pending_occurrence, user: nil, source: :rain)
      expect(plant.watering_task.reload).to be_moved_by_rain

      travel 10.days
      Tasks::MarkMissed.new.call
      sign_in(user)
      get plant_path(plant)

      expect(plant.watering_task.reload).not_to be_moved_by_rain
      expect(response.parsed_body.text.squish).not_to include("Reporté par la pluie")
    end

    it "falls back to the care tab on an unknown tab" do
      plant = create(:plant, :watered, household:, name: "Basilic")
      sign_in(user)

      get plant_path(plant, tab: "unknown")

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/aria-current="page"[^>]*>\s*Soins/)
    end

    it "does not find the plant of another household" do
      sign_in(user)

      get plant_path(create(:plant))

      expect(response).to have_http_status(:not_found)
    end

    it "does not show the plant to a guest" do
      sign_in(guest)

      get plant_path(create(:plant, household:))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /plants/:id" do
    let(:plant) { create(:plant, :watered, household:, name: "Basilic", interval_days: 2) }

    it "saves the new interval" do
      sign_in(user)

      patch plant_path(plant), params: { plant: { name: "Basilic", watering_interval_days: "4" } }

      expect(response).to redirect_to(plant_path(plant))
      expect(plant.watering_task.reload.recurrence.interval_days).to eq(4)
    end

    it "renders the form again without a name" do
      sign_in(user)

      patch plant_path(plant), params: { plant: { name: "", watering_interval_days: "4" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nom doit être rempli(e)")
      expect(plant.reload.name).to eq("Basilic")
    end
  end

  describe "archiving and deletion" do
    let(:plant) { create(:plant, :watered, household:, name: "Basilic") }

    it "archives then restores a plant" do
      sign_in(user)

      post plant_archive_path(plant)
      expect(plant.reload).to be_archived

      delete plant_archive_path(plant)
      expect(plant.reload).not_to be_archived
    end

    it "deletes a plant and its history" do
      sign_in(user)

      delete plant_path(plant)

      expect(response).to redirect_to(plants_path)
      expect(Plant.exists?(plant.id)).to be(false)
      expect(TaskOccurrence.count).to eq(0)
    end
  end

  describe "access denied on every write" do
    let(:plant) { create(:plant, :watered, household:, name: "Basilic") }
    let(:pending_occurrence) { plant.watering_task.pending_occurrence }
    let(:watering) { plant.watering_task.occurrences.done.sole }
    let(:requests) do
      {
        "edit form" => -> { get edit_plant_path(plant) },
        "update" => -> { patch plant_path(plant), params: { plant: { name: "X", watering_interval_days: "4" } } },
        "destroy" => -> { delete plant_path(plant) },
        "archive" => -> { post plant_archive_path(plant) },
        "restore" => -> { delete plant_archive_path(plant) },
        "watering" => -> { post task_occurrence_completion_path(pending_occurrence) },
        "watering cancellation" => -> { delete task_occurrence_completion_path(watering) }
      }
    end

    {
      "a guest of the household" => -> { guest },
      "a user of another household" => -> { create(:user, :with_household) }
    }.each do |intruder_label, intruder|
      [ "edit form", "update", "destroy", "archive", "restore", "watering", "watering cancellation" ].each do |action|
        it "answers 404 to #{intruder_label} on #{action}, without changing anything" do
          pending_occurrence
          watering
          sign_in(instance_exec(&intruder))

          instance_exec(&requests.fetch(action))

          expect(response).to have_http_status(:not_found)
          expect(plant.reload).to have_attributes(name: "Basilic", archived_at: nil)
          expect(pending_occurrence.reload).to be_pending
          expect(watering.reload).to be_done
        end
      end
    end

    it "answers 403 to a guest on the new plant form" do
      sign_in(guest)

      get new_plant_path

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /task_occurrences/:id/completion" do
    it "cancels a watering and recomputes the next one" do
      plant = create(:plant, :watered, household:, name: "Basilic", interval_days: 2)
      sign_in(user)
      post task_occurrence_completion_path(plant.watering_task.pending_occurrence)
      watering = plant.watering_task.occurrences.done.order(:completed_at).last

      delete task_occurrence_completion_path(watering)

      expect(flash[:notice]).to eq("Arrosage annulé, prochaine échéance recalculée.")
      expect(TaskOccurrence.exists?(watering.id)).to be(false)
      expect(plant.reload.watering_task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-17 00:00"))
    end
  end

  describe "failure messages" do
    let(:plant) { create(:plant, :watered, household:, name: "Basilic", interval_days: 2) }

    before { sign_in(user) }

    it "rejects a second watering on the same day" do
      post task_occurrence_completion_path(plant.watering_task.pending_occurrence)
      post task_occurrence_completion_path(plant.reload.watering_task.pending_occurrence)

      expect(flash[:notice]).to eq("Déjà fait aujourd'hui.")
    end

    it "rejects the watering of a stopped task" do
      plant.watering_task.update!(active: false)

      post task_occurrence_completion_path(plant.watering_task.pending_occurrence)

      expect(flash[:notice]).to eq("Cette tâche est arrêtée.")
    end

    it "cancels nothing on an occurrence not done yet" do
      delete task_occurrence_completion_path(plant.watering_task.pending_occurrence)

      expect(flash[:notice]).to eq("Rien à annuler.")
      expect(plant.watering_task.occurrences.count).to eq(2)
    end

    it "cancels a watering of an archived plant without recreating an occurrence" do
      post plant_archive_path(plant)

      delete task_occurrence_completion_path(plant.watering_task.occurrences.done.sole)

      expect(flash[:notice]).to eq("Arrosage annulé.")
      expect(plant.watering_task.occurrences).to be_empty
    end

    it "reports a plant already archived, or not archived" do
      post plant_archive_path(plant)
      post plant_archive_path(plant)
      expect(flash[:notice]).to eq("« Basilic » était déjà archivée.")

      delete plant_archive_path(plant)
      delete plant_archive_path(plant)
      expect(flash[:notice]).to eq("« Basilic » n'était pas archivée.")
    end
  end

  describe "POST /task_occurrences/:id/postponement" do
    let(:plant) { create(:plant, :watered, household:, name: "Basilic", interval_days: 2) }
    let(:occurrence) { plant.watering_task.pending_occurrence }

    before { occurrence.update!(due_at: Time.zone.today.in_time_zone) }

    it "postpones the task to tomorrow and goes back to the previous page" do
      sign_in(user)

      post task_occurrence_postponement_path(occurrence), headers: { "HTTP_REFERER" => root_url }

      expect(response).to redirect_to(root_url)
      expect(flash[:notice]).to eq("Reporté à demain : Arrosage (Basilic).")
      expect(occurrence.reload).to be_postponed
      expect(TaskOccurrence.pending.find_by(task: occurrence.task).due_at.to_date).to eq(Time.zone.tomorrow)
    end

    it "names only the task in the toast when it has no subject (bins, to come)" do
      task = create(:task, household:, subject: nil, title: "Sortir la poubelle jaune", template_key: nil,
                           recurrence_type: :once, recurrence_config: { "due_on" => "2026-11-16" })
      bins = task.occurrences.create!(due_at: Time.zone.today.in_time_zone)
      sign_in(user)

      post task_occurrence_postponement_path(bins)

      expect(flash[:notice]).to eq("Reporté à demain : Sortir la poubelle jaune.")
    end

    it "is undone from the toast" do
      sign_in(user)

      post task_occurrence_postponement_path(occurrence)
      expect(flash[:undo_postponement_id]).to eq(occurrence.id)

      delete task_occurrence_postponement_path(occurrence)
      expect(flash[:notice]).to eq("Décalage annulé.")
      expect(occurrence.reload).to be_pending
      expect(plant.watering_task.occurrences.pending.sole).to eq(occurrence)
    end

    it "lets the toast of a stale \"Fait\" undo the task actually done" do
      sign_in(user)
      post task_occurrence_postponement_path(occurrence)
      tomorrow = TaskOccurrence.pending.find_by(task: occurrence.task)

      post task_occurrence_completion_path(occurrence) # the postponed one, from a page shown before

      expect(flash[:undo_ids]).to eq([ tomorrow.id ])
      expect(tomorrow.reload).to be_done
    end

    it "rejects the occurrence of another household, and a guest" do
      other = create(:plant, :watered).watering_task.pending_occurrence
      sign_in(user)
      post task_occurrence_postponement_path(other)
      expect(response).to have_http_status(:not_found)

      sign_in(guest)
      post task_occurrence_postponement_path(occurrence)
      expect(response).to have_http_status(:not_found)
      expect([ other.reload, occurrence.reload ]).to all(be_pending)
    end
  end

  describe "POST /task_occurrences/:id/completion" do
    let(:plant) { create(:plant, :watered, household:, name: "Basilic", interval_days: 2) }
    let(:occurrence) { plant.watering_task.pending_occurrence }

    it "records the watering and goes back to the previous page" do
      sign_in(user)

      post task_occurrence_completion_path(occurrence), headers: { "HTTP_REFERER" => plant_url(plant) }

      expect(response).to redirect_to(plant_url(plant))
      expect(flash[:notice]).to eq("Arrosage noté pour « Basilic ».")
      expect(occurrence.reload).to be_done
    end

    it "counts a single watering on a double tap" do
      sign_in(user)

      2.times { post task_occurrence_completion_path(occurrence) }

      expect(flash[:notice]).to eq("C'était déjà fait.")
      expect(plant.watering_task.occurrences.done.count).to eq(2)
    end

    it "rejects the occurrence of another household" do
      other = create(:plant, :watered).watering_task.pending_occurrence
      sign_in(user)

      post task_occurrence_completion_path(other)

      expect(response).to have_http_status(:not_found)
      expect(other.reload).to be_pending
    end
  end
end
