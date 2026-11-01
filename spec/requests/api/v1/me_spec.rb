require "rails_helper"

RSpec.describe "API me", type: :request do
  let(:user) { create(:user) }
  let(:headers) { {Authorization: "Bearer #{create(:session, user: user).token}"} }

  describe "GET /api/v1/me" do
    it "returns the current user" do
      get api_v1_me_path, headers: headers
      expect(response.parsed_body).to eq(
        "id" => user.id, "email_address" => user.email_address,
        "first_name" => user.first_name, "last_name" => user.last_name, "unit_system" => "us_customary"
      )
    end
  end

  describe "PATCH /api/v1/me" do
    it "updates the name and unit system" do
      patch api_v1_me_path, params: {user: {first_name: "Ada", unit_system: "metric"}}, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("first_name" => "Ada", "unit_system" => "metric")
      expect(user.reload).to be_metric
    end

    it "rejects an unknown unit system" do
      patch api_v1_me_path, params: {user: {unit_system: "imperial"}}, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to have_key("unit_system")
    end

    it "doesn't change the email address or password" do
      patch api_v1_me_path, params: {user: {email_address: "new@example.com", password: "changed123"}}, headers: headers, as: :json
      expect(user.reload.email_address).not_to eq("new@example.com")
      expect(user.authenticate("password123")).to be_truthy
    end
  end

  describe "DELETE /api/v1/me" do
    it "deactivates the account and revokes every token" do
      other_token = create(:session, user: user).token
      freeze_time do
        delete api_v1_me_path, params: {password: "password123"}, headers: headers, as: :json
        expect(response).to have_http_status(:ok)
        expect(Time.zone.parse(response.parsed_body["deletes_at"])).to eq(User::DELETION_GRACE_PERIOD.from_now)
      end
      expect(user.reload).to be_deactivated

      get api_v1_me_path, headers: headers
      expect(response).to have_http_status(:unauthorized)
      get api_v1_me_path, headers: {Authorization: "Bearer #{other_token}"}
      expect(response).to have_http_status(:unauthorized)
    end

    it "requires the correct password" do
      delete api_v1_me_path, params: {password: "wrong-password"}, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq("errors" => {"password" => ["is incorrect"]})
      expect(user.reload).not_to be_deactivated

      delete api_v1_me_path, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "hides the user's recipes from others" do
      recipe = create(:recipe, user: user)
      viewer = {Authorization: "Bearer #{create(:session).token}"}
      delete api_v1_me_path, params: {password: "password123"}, headers: headers, as: :json

      get api_v1_recipe_path(recipe), headers: viewer
      expect(response).to have_http_status(:not_found)
      get api_v1_recipes_path, headers: viewer
      expect(response.parsed_body["recipes"]).to be_empty
    end
  end
end
