require "rails_helper"

RSpec.describe "My account", type: :request do
  let(:user) { create(:user, :with_household, email: "lea@example.com") }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "passwordpassword" }
  end

  it "shows the first name and the email from the settings" do
    sign_in(user)

    get settings_path
    expect(response.parsed_body.at_css("a[href='#{edit_account_path}']").text.squish).to eq("Lea lea@example.com")

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

  it "deletes the account with the password, says what goes with it, then signs out" do
    sign_in(user)

    get edit_account_path
    expect(response.parsed_body.at_css("#households-alone").text.squish).to include("Maison de test")

    delete account_path, params: { password: "mauvais" }
    expect(flash[:alert]).to eq("Mot de passe incorrect : rien n'a été supprimé.")
    expect(user.reload).to be_present

    delete account_path, params: { password: "passwordpassword" }
    expect(response).to redirect_to(new_session_path)
    expect(User.exists?(user.id)).to be(false)
    get root_path
    expect(response).to redirect_to(new_session_path)
  end

  it "asks the last manager of a shared household to name another one first" do
    household = user.households.sole
    create(:household_member, household:, role: :member)
    sign_in(user)

    get edit_account_path

    expect(response.parsed_body.at_css("#hand-over").text).to include("Maison de test")
    expect(response.parsed_body.at_css("form[action='#{account_path}'] input[name=password]")).to be_nil
  end

  it "asks a visitor to sign in" do
    get edit_account_path

    expect(response).to redirect_to(new_session_path)
  end
end
