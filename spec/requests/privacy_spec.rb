require "rails_helper"

RSpec.describe "Privacy", type: :request do
  it "is public and says how to delete one's account" do
    get privacy_path

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.text.squish).to include("Confidentialité", "Supprimer son compte", "Firebase")
  end
end
