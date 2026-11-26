require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#reset" do
    let(:user) { create(:user) }
    let(:mail) { described_class.reset(user) }

    it "sends a French reset email to the user" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to eq("Réinitialisation de votre mot de passe")
      expect(mail.text_part.body.to_s).to include("Ce lien expire dans")
    end

    it "is sent from the address of MAIL_FROM, read when the email is built" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("MAIL_FROM", anything).and_return("Easy Home <no-reply@mail.example.org>")

      expect(mail.from).to eq([ "no-reply@mail.example.org" ])
      expect(mail[:from].display_names).to eq([ "Easy Home" ])
    end

    it "falls back to a placeholder sender without MAIL_FROM (development, tests, image build)" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("MAIL_FROM", anything) { |_name, default| default }

      expect(mail.from).to eq([ "no-reply@example.com" ])
    end
  end
end
