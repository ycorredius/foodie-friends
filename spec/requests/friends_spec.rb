# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Friends", type: :request do
  let(:user1) { FactoryBot.create(:random_user, :with_api_token) }
  let(:user2) { FactoryBot.create(:random_user, :with_api_token) }
  let(:auth_headers) { {Authorization: "Bearer #{create(:api_token, user: user1).token}"} }

  before(:each) do
    post api_v1_user_friends_path(id: user2.id),
      headers: auth_headers
    expect(response).to have_http_status(:success)
  end

  describe "Post /create" do
    it "successfully creates an invitation relationship" do
      expect(response).to have_http_status(:success)
      user2.accept_invitation(user1)
      expect(user1.friends.count).to eq(1)
    end
  end

  describe "GET /index" do
    it "returns all user's friends" do
      user2.accept_invitation(user1)
      get api_v1_user_friends_path,
        headers: auth_headers
      expect(response).to have_http_status(:success)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["friends"].count).to eq(1)
    end
  end

  describe "DELETE /destroy" do
    it "successfully destroys friendship" do
      user2.accept_invitation(user1)
      expect(user1.friends.count).to eq(1)
      delete api_v1_user_friend_path(user2.id),
        headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(user1.friends.count).to eq(0)
      expect(Invitation.all.count).to eq(0)
    end
  end
end
