require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) { create(:user) }

  describe "GET /passwords/new" do
    it "renders the form in French" do
      get new_password_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mot de passe oublié ?")
    end
  end

  describe "POST /passwords" do
    it "sends reset instructions to a known address" do
      expect { post passwords_path, params: { email_address: user.email_address } }
        .to have_enqueued_mail(PasswordsMailer, :reset)

      expect(response).to redirect_to(new_session_path)
    end

    it "does not reveal an unknown address" do
      expect { post passwords_path, params: { email_address: "unknown@example.com" } }
        .not_to have_enqueued_mail(PasswordsMailer, :reset)

      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /passwords/:token/edit" do
    it "renders the form with a valid token" do
      get edit_password_path(user.password_reset_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nouveau mot de passe")
    end

    it "redirects with a French alert on an invalid token" do
      get edit_password_path("invalid")

      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to eq("Le lien de réinitialisation est invalide ou a expiré.")
    end
  end

  describe "PUT /passwords/:token" do
    it "updates the password" do
      put password_path(user.password_reset_token), params: { password: "new-pass", password_confirmation: "new-pass" }

      expect(response).to redirect_to(new_session_path)
      expect(user.reload.authenticate("new-pass")).to be_truthy
    end

    it "rejects a mismatched confirmation" do
      token = user.password_reset_token

      put password_path(token), params: { password: "new-pass", password_confirmation: "other" }

      expect(response).to redirect_to(edit_password_path(token))
      expect(flash[:alert]).to eq("Les mots de passe ne correspondent pas.")
    end
  end
end
