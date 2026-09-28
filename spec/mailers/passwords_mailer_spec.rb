require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#reset" do
    let(:user) { create(:user) }
    let(:mail) { described_class.reset(user) }

    it "sends a French reset email to the user" do
      expect(mail.to).to eq([ user.email_address ])
      expect(mail.subject).to eq("Réinitialisation de votre mot de passe")
      expect(mail.text_part.body.to_s).to include("Ce lien expire dans")
    end
  end
end
