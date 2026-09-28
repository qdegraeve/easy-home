require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user) }

  describe "GET /session/new" do
    it "renders the sign in form in French" do
      get new_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Se connecter")
    end
  end

  describe "POST /session" do
    it "signs the user in with valid credentials" do
      post session_path, params: { email_address: user.email_address, password: "password" }

      expect(response).to redirect_to(root_url)
      expect(user.sessions.count).to eq(1)
    end

    it "redirects back with a French alert on invalid credentials" do
      post session_path, params: { email_address: user.email_address, password: "wrong" }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("Adresse e-mail ou mot de passe incorrect.")
    end
  end

  describe "DELETE /session" do
    it "signs the user out" do
      post session_path, params: { email_address: user.email_address, password: "password" }

      delete session_path

      expect(response).to redirect_to(new_session_path)
      expect(user.sessions.count).to eq(0)
    end
  end
end
