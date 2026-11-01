require "rails_helper"

RSpec.describe "Api::V1::Auths", type: :request do
  let(:user) { create(:user, password: "password123") }

  def login(password: "password123", email: user.email)
    post api_v1_auths_path, params: {email: email, password: password}
  end

  def auth_headers(token)
    {Authorization: "Bearer #{token}"}
  end

  describe "POST /api/v1/auths" do
    it "returns a working token for valid credentials" do
      login
      expect(response).to have_http_status(:ok)
      token = response.parsed_body["token"]

      get api_v1_me_path, headers: auth_headers(token)
      expect(response).to have_http_status(:ok)
    end

    it "issues a new token on each login" do
      login
      first = response.parsed_body["token"]
      login
      expect(response.parsed_body["token"]).not_to eq(first)
      expect(user.api_tokens.count).to eq(2)
    end

    it "deletes the user's expired tokens" do
      create(:api_token, user: user).update_columns(expires_at: 1.day.ago)
      login
      expect(user.api_tokens.count).to eq(1)
    end

    it "rejects a wrong password" do
      login(password: "wrong")
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).not_to have_key("token")
    end

    it "rejects an unknown email" do
      login(email: "nobody@example.com")
      expect(response).to have_http_status(:unauthorized)
    end

    it "doesn't update Devise sign-in tracking on API requests" do
      token = create(:api_token, user: user).token
      expect { get api_v1_me_path, headers: auth_headers(token) }
        .not_to change { user.reload.sign_in_count }
    end
  end

  describe "DELETE /api/v1/auths" do
    it "revokes only the token used for the request" do
      token = create(:api_token, user: user).token
      other_token = create(:api_token, user: user).token

      delete api_v1_auths_path, headers: auth_headers(token)
      expect(response).to have_http_status(:no_content)

      get api_v1_me_path, headers: auth_headers(token)
      expect(response).to have_http_status(:unauthorized)
      get api_v1_me_path, headers: auth_headers(other_token)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "token authentication" do
    it "rejects requests without a token" do
      get api_v1_me_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an expired token" do
      api_token = create(:api_token, user: user)
      api_token.update_columns(expires_at: 1.second.ago)
      get api_v1_me_path, headers: auth_headers(api_token.token)
      expect(response).to have_http_status(:unauthorized)
    end

    it "extends the token's expiry when used" do
      api_token = create(:api_token, user: user)
      api_token.update_columns(expires_at: 1.day.from_now)
      get api_v1_me_path, headers: auth_headers(api_token.token)
      expect(api_token.reload.expires_at).to be_within(1.minute).of(ApiToken::TTL.from_now)
    end
  end

  describe "POST /api/v1/user (sign up)" do
    it "returns a working token" do
      post api_v1_user_path, params: {user: {email: "new@example.com", password: "password123",
                                             password_confirmation: "password123", first_name: "New", last_name: "User"}}
      expect(response).to have_http_status(:created)

      get api_v1_me_path, headers: auth_headers(response.parsed_body["token"])
      expect(response).to have_http_status(:ok)
    end
  end
end
