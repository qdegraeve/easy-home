require "rails_helper"

RSpec.describe "Push devices", type: :request do
  let(:user) { create(:user) }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "passwordpassword" }
  end

  it "registers the phone of the signed-in session" do
    sign_in(user)

    post push_devices_path, params: { push_device: { token: "fcm-1", name: "Galaxy" } }, as: :json

    expect(response).to have_http_status(:created)
    expect(ApplicationPushDevice.sole).to have_attributes(
      token: "fcm-1", name: "Galaxy", platform: "google", owner: user.sessions.sole
    )
  end

  it "keeps one device per token: a phone signed in by someone else moves to that session" do
    sign_in(user)
    post push_devices_path, params: { push_device: { token: "fcm-1" } }, as: :json
    delete session_path
    other = create(:user)
    create(:push_device, token: "fcm-1", owner: create(:session, user:)) # left by an old session
    sign_in(other)

    post push_devices_path, params: { push_device: { token: "fcm-1" } }, as: :json

    expect(ApplicationPushDevice.sole.owner.user).to eq(other)
  end

  it "forgets the phone on sign out" do
    sign_in(user)
    post push_devices_path, params: { push_device: { token: "fcm-1" } }, as: :json

    delete session_path

    expect(ApplicationPushDevice.count).to eq(0)
  end

  it "refuses a missing token" do
    sign_in(user)

    post push_devices_path, params: { push_device: { token: "" } }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(ApplicationPushDevice.count).to eq(0)
  end

  it "requires to be signed in" do
    post push_devices_path, params: { push_device: { token: "fcm-1" } }, as: :json

    expect(response).to redirect_to(new_session_path)
    expect(ApplicationPushDevice.count).to eq(0)
  end
end
