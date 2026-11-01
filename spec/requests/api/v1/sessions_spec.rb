require "rails_helper"

RSpec.describe "API sessions", type: :request do
  let(:user) { create(:user) }

  def bearer(token)
    {Authorization: "Bearer #{token}"}
  end

  def sign_in(password: "password123", email_address: user.email_address)
    post api_v1_session_path, params: {email_address: email_address, password: password}, as: :json
  end

  describe "POST /api/v1/session" do
    it "returns a working token and the user" do
      sign_in
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["user"]).to include("id" => user.id, "email_address" => user.email_address)

      get api_v1_me_path, headers: bearer(response.parsed_body["token"])
      expect(response).to have_http_status(:ok)
    end

    it "issues a new token on each sign-in" do
      sign_in
      first = response.parsed_body["token"]
      sign_in
      expect(response.parsed_body["token"]).not_to eq(first)
    end

    it "rejects a wrong password" do
      sign_in(password: "wrong-password")
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).not_to have_key("token")
    end

    it "rejects an unknown email address" do
      sign_in(email_address: "nobody@example.com")
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/session" do
    it "revokes only the token used for the request" do
      token = create(:session, user: user).token
      other_token = create(:session, user: user).token

      delete api_v1_session_path, headers: bearer(token)
      expect(response).to have_http_status(:no_content)

      get api_v1_me_path, headers: bearer(token)
      expect(response).to have_http_status(:unauthorized)
      get api_v1_me_path, headers: bearer(other_token)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "token authentication" do
    it "rejects requests without a token" do
      get api_v1_me_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an expired token" do
      session = create(:session, user: user)
      session.update_columns(expires_at: 1.second.ago)
      get api_v1_me_path, headers: bearer(session.token)
      expect(response).to have_http_status(:unauthorized)
    end

    it "extends the token's expiry when used" do
      session = create(:session, user: user)
      session.update_columns(expires_at: 1.day.from_now)
      get api_v1_me_path, headers: bearer(session.token)
      expect(session.reload.expires_at).to be_within(1.minute).of(Session::TTL.from_now)
    end

    it "ignores the browser session cookie" do
      post session_path, params: {email_address: user.email_address, password: "password123"}
      get api_v1_me_path
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/me" do
    it "returns the current user" do
      get api_v1_me_path, headers: bearer(create(:session, user: user).token)
      expect(response.parsed_body).to eq(
        "id" => user.id, "email_address" => user.email_address,
        "first_name" => user.first_name, "last_name" => user.last_name
      )
    end
  end
end
