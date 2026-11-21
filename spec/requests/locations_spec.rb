require "rails_helper"

RSpec.describe "Locations", type: :request do
  let(:household) { create(:household) }
  let(:owner) { create(:household_member, household:, role: :owner).user }
  let(:location) { create(:location, household:, name: "Terrasse", exposure: :partial_shade) }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  def change(location, **attributes)
    patch location_path(location), params: { location: { name: location.name, exposure: location.exposure,
                                                         sheltered: location.sheltered? }.merge(attributes) }
  end

  it "changes the exposure of a location, and warns before about the analyses of its plants" do
    create(:plant, household:, location:)
    sign_in(owner)

    get edit_location_path(location)
    expect(response.body).to include("signalera l&#39;analyse de sa plante à revoir")

    change(location, exposure: "full_sun", sheltered: true)

    expect(response).to redirect_to(edit_household_path(household))
    expect(location.reload).to have_attributes(exposure: "full_sun", sheltered: true)
  end

  it "renders the form again on a missing name" do
    sign_in(owner)

    change(location, name: "")

    expect(response).to have_http_status(:unprocessable_content)
    expect(location.reload.name).to eq("Terrasse")
  end

  it "does not let a guest change a location, nor find the one of another household" do
    sign_in(create(:household_member, household:, role: :guest).user)
    change(location, exposure: "shade")
    expect(response).to have_http_status(:forbidden)

    sign_in(owner)
    change(create(:location), exposure: "shade")
    expect(response).to have_http_status(:not_found)
    expect(location.reload.exposure).to eq("partial_shade")
  end
end
