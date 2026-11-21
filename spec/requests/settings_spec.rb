require "rails_helper"

RSpec.describe "Settings", type: :request do
  it "shows the account, the preferences and signing out" do
    user = create(:user, :with_household, email: "moi@example.com")
    post session_path, params: { email: user.email, password: "password" }

    get settings_path

    expect(response.parsed_body.text.squish).to include("moi@example.com", "Notifications", "Mes foyers")
    sign_out = response.parsed_body.at_css("form[action='#{session_path}']")
    expect(sign_out["data-turbo-confirm"]).to eq("Se déconnecter ?")
  end

  it "asks a visitor to sign in" do
    get settings_path

    expect(response).to redirect_to(new_session_path)
  end
end
