require "rails_helper"

# config/push.yml (ADR 0012): the Firebase settings come from the credentials. The project id is read from the
# service account key when the credentials do not give it: an empty one makes every sending fail (FCM 400).
RSpec.describe "Push configuration" do
  let(:key) do
    { type: "service_account", project_id: "easy-home-123", private_key: "-----BEGIN PRIVATE KEY-----\nx\n" }
  end

  def google_config(fcm)
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:action_push_native, :fcm).and_return(fcm)
    ActionPushNative.config.fetch(:google)
  end

  it "reads the project id from the key when the credentials leave it empty" do
    config = google_config({ encryption_key: key.to_json, project_id: nil })

    expect(config[:project_id]).to eq("easy-home-123")
    expect(JSON.parse(config[:encryption_key])["private_key"]).to eq(key[:private_key])
  end

  it "keeps the project id of the credentials when given" do
    config = google_config({ encryption_key: key.to_json, project_id: "other-project" })

    expect(config[:project_id]).to eq("other-project")
  end

  it "loads without any Firebase credentials (development without Firebase, tests)" do
    config = google_config(nil)

    expect(config.values_at(:project_id, :encryption_key)).to all(be_nil)
  end
end
