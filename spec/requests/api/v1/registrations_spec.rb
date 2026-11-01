require "rails_helper"

RSpec.describe "API registrations", type: :request do
  let(:valid_params) do
    {user: {first_name: "New", last_name: "User", email_address: "new@example.com",
            password: "password123", password_confirmation: "password123"}}
  end

  it "creates the user and returns a working token" do
    expect { post api_v1_registration_path, params: valid_params, as: :json }.to change(User, :count).by(1)
    expect(response).to have_http_status(:created)

    get api_v1_me_path, headers: {Authorization: "Bearer #{response.parsed_body["token"]}"}
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["email_address"]).to eq("new@example.com")
  end

  it "returns validation errors" do
    create(:user, email_address: "new@example.com")
    post api_v1_registration_path, params: valid_params, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body["errors"]).to have_key("email_address")
  end
end
