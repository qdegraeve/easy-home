require "rails_helper"

RSpec.describe "Notification settings", type: :request do
  let(:home) { create(:household, name: "Maison") }
  let(:user) { create(:household_member, household: home, role: :owner).user }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  it "shows the current settings" do
    create(:household_member, user:, role: :member, household: create(:household, name: "Chez Mamie"))
    sign_in(user)

    get edit_notification_settings_path

    expect(response.body).to include("Recevoir le résumé du matin", "Maison", "Chez Mamie")
    expect(response.body).to include("Les notifications arrivent sur les téléphones")
    expect(response.body).to match(/<option selected="selected" value="08:00">/)
  end

  it "tells in the app that this phone does not get the notifications yet" do
    sign_in(user)

    app = "Mozilla/5.0 (Linux; Android 17) Hotwire Native Android"
    get edit_notification_settings_path, headers: { "User-Agent" => app }

    expect(response.parsed_body.text.squish).to include("Ce téléphone ne reçoit pas encore les notifications")
  end

  it "answers a refused change with the page and its error, even to a change saved from the page" do
    sign_in(user)

    patch notification_settings_path,
      params: { notification_settings: { digest_enabled: "1", digest_time: "25:00", critical_only: "0" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.media_type).to eq("text/html")
    expect(response.body).to include("Recevoir le résumé du matin")
  end

  it "saves the switch, the time and the followed households" do
    other = create(:household_member, user:, role: :member, household: create(:household, name: "Chez Mamie"))
    sign_in(user)

    patch notification_settings_path, params: {
      notification_settings: {
        digest_enabled: "0",
        digest_time: "07:15",
        critical_only: "0",
        household_ids: [ home.id ]
      }
    }

    expect(response).to redirect_to(edit_notification_settings_path)
    expect(user.reload).to have_attributes(digest_enabled: false, digest_minute: 7 * 60 + 15)
    expect(other.reload.digest).to be(false)
    expect(user.household_members.find_by(household: home).digest).to be(true)
  end

  it "answers a change saved from the page with the toast only, leaving the form as it is" do
    sign_in(user)

    patch notification_settings_path,
      params: {
        notification_settings: {
          digest_enabled: "0",
          digest_time: "08:00",
          critical_only: "0",
          household_ids: [ home.id ]
        }
      },
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include('action="replace" target="toasts"', "Enregistré.")
    expect(response.body).not_to include("Recevoir le résumé du matin")
    expect(user.reload.digest_enabled).to be(false)
  end

  it "saves the digest scope: only what must not be missed, then everything again" do
    sign_in(user)
    settings = { digest_enabled: "1", digest_time: "08:00", household_ids: [ home.id ] }

    patch notification_settings_path, params: { notification_settings: settings.merge(critical_only: "1") }
    expect(user.reload).to be_digest_critical
    get edit_notification_settings_path
    expect(response.parsed_body.at_css("input[type=checkbox][name='notification_settings[critical_only]']")["checked"])
      .to eq("checked")

    patch notification_settings_path, params: { notification_settings: settings.merge(critical_only: "0") }
    expect(user.reload).to be_digest_all
  end

  it "refuses a time off the quarter hours and a household the user does not manage" do
    guest_of = create(:household_member, user:, role: :guest).household
    sign_in(user)

    patch notification_settings_path, params: {
      notification_settings: {
        digest_enabled: "1",
        digest_time: "07:10",
        critical_only: "0",
        household_ids: [ guest_of.id ]
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Heure du résumé", "Foyers")
    expect(user.reload.digest_minute).to eq(8 * 60)
  end

  it "keeps the only household followed: its checkbox is not shown" do
    sign_in(user)
    get edit_notification_settings_path
    expect(response.body).not_to include("Foyers à inclure")

    patch notification_settings_path, params: {
      notification_settings: {
        digest_enabled: "1",
        digest_time: "08:00",
        critical_only: "0",
        household_ids: [ home.id ]
      }
    }

    expect(user.household_members.sole.digest).to be(true)
  end

  it "refuses a request without the switch instead of failing" do
    sign_in(user)

    patch notification_settings_path, params: { notification_settings: { digest_time: "08:00" } }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "counts the phones that receive the notifications" do
    sign_in(user)
    create_list(:push_device, 2, owner: user.sessions.last)

    get edit_notification_settings_path

    expect(response.body).to include("2 téléphones reçoivent les notifications.")
  end

  it "requires to be signed in" do
    get edit_notification_settings_path

    expect(response).to redirect_to(new_session_path)
  end

  describe "test notification" do
    include ActiveJob::TestHelper

    it "sends a test notification to each phone of the user" do
      sign_in(user)
      device = create(:push_device, owner: user.sessions.last)
      create(:push_device) # someone else's phone

      expect { post test_notification_path }
        .to have_enqueued_job(ApplicationPushNotificationJob).exactly(:once)
        .with("ApplicationPushNotification", hash_including(title: "Notification de test"), device)
      expect(flash[:notice]).to eq("Notification de test envoyée à 1 téléphone.")
    end

    it "explains that no phone is registered yet" do
      sign_in(user)

      post test_notification_path

      expect(flash[:alert]).to eq("Aucun téléphone n'est enregistré pour les notifications.")
    end
  end
end
