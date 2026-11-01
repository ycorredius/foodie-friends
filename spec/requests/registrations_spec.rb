require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:valid_params) do
    {user: {first_name: "New", last_name: "User", email_address: "new@example.com",
            password: "password123", password_confirmation: "password123"}}
  end

  it "renders the sign-up form" do
    get new_registration_path
    expect(response).to have_http_status(:ok)
  end

  it "creates the user and signs them in" do
    expect { post registration_path, params: valid_params }.to change(User, :count).by(1)
    expect(response).to redirect_to(root_path)
    get root_path
    expect(response).to have_http_status(:ok)
  end

  it "re-renders the form with errors for invalid input" do
    valid_params[:user][:password_confirmation] = "different"
    expect { post registration_path, params: valid_params }.not_to change(User, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("doesn&#39;t match Password")
  end
end
