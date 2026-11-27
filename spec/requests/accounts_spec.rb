require "rails_helper"

RSpec.describe "My account", type: :request do
  let(:user) { create(:user, :with_household, email: "lea@example.com") }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  it "shows the first name and the email from the settings" do
    sign_in(user)

    get settings_path
    expect(response.parsed_body.at_css("a[href='#{edit_account_path}']").text.squish).to eq("lea lea@example.com")

    get edit_account_path
    expect(response.parsed_body.text.squish).to include("Mon compte", "Prénom", "lea@example.com")
  end

  it "saves the first name, then shows it in the settings" do
    sign_in(user)

    patch account_path, params: { user: { name: " Léa " } }

    expect(response).to redirect_to(settings_path)
    expect(user.reload.name).to eq("Léa")
    get settings_path
    expect(response.parsed_body.at_css("a[href='#{edit_account_path}']").text.squish).to start_with("Léa")
  end

  it "refuses a name too long, and never changes the email" do
    sign_in(user)

    patch account_path, params: { user: { name: "L" * 51, email: "autre@example.com" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(user.reload).to have_attributes(name: nil, email: "lea@example.com")
  end

  it "asks a visitor to sign in" do
    get edit_account_path

    expect(response).to redirect_to(new_session_path)
  end
end
