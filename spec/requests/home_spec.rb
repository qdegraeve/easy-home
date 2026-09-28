require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "redirects a visitor to the sign in form" do
      get root_path

      expect(response).to redirect_to(new_session_path)
    end

    it "renders the page for a signed in user" do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Se déconnecter")
    end
  end
end
