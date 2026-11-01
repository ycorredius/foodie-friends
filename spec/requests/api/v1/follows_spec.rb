require "rails_helper"

RSpec.describe "API profiles and follows", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth(user) }
  let(:public_user) { create(:user) }
  let(:private_user) { create(:user, private_profile: true) }

  def auth(user)
    {Authorization: "Bearer #{create(:session, user: user).token}"}
  end

  def ids(body = response.parsed_body)
    body["users"].map { |u| u["id"] }
  end

  describe "GET /api/v1/users/:id" do
    it "returns the profile with counts and the relationship" do
      create(:recipe, user: public_user)
      create(:recipe, :only_me, user: public_user)
      public_user.follow(user)
      user.follow(public_user)

      get api_v1_user_path(public_user), headers: headers
      expect(response.parsed_body).to include(
        "id" => public_user.id, "private_profile" => false, "followers_count" => 1, "following_count" => 1,
        "recipes_count" => 1, "follow_status" => "accepted", "follows_you" => true
      )
      expect(response.parsed_body).not_to have_key("email_address")
    end

    it "shows a pending request and hides a private profile's recipe count" do
      create(:recipe, user: private_user)
      user.follow(private_user)
      get api_v1_user_path(private_user), headers: headers
      expect(response.parsed_body).to include("follow_status" => "pending", "recipes_count" => 0)
    end

    it "404s for deactivated users" do
      public_user.deactivate!
      get api_v1_user_path(public_user), headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/users/:user_id/follow" do
    it "follows a public profile" do
      post api_v1_user_follow_path(public_user), headers: headers
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq("status" => "accepted")
    end

    it "requests to follow a private profile" do
      post api_v1_user_follow_path(private_user), headers: headers
      expect(response.parsed_body).to eq("status" => "pending")
    end

    it "returns 200 with the existing follow when repeated" do
      2.times { post api_v1_user_follow_path(public_user), headers: headers }
      expect(response).to have_http_status(:ok)
      expect(Follow.count).to eq(1)
    end

    it "can't follow yourself" do
      post api_v1_user_follow_path(user), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  it "DELETE /api/v1/users/:user_id/follow unfollows or cancels a request" do
    user.follow(public_user)
    user.follow(private_user)
    delete api_v1_user_follow_path(public_user), headers: headers
    delete api_v1_user_follow_path(private_user), headers: headers
    expect(response).to have_http_status(:no_content)
    expect(Follow.count).to eq(0)
  end

  describe "follower and following lists" do
    it "lists followers and following, newest first, without deactivated users" do
      older, newer, gone = create_list(:user, 3)
      [older, newer, gone].each { |follower| follower.follow(public_user) }
      public_user.follow(older)
      gone.deactivate!

      get api_v1_user_followers_path(public_user), headers: headers
      expect(ids).to eq([newer.id, older.id])

      get api_v1_user_following_index_path(public_user), headers: headers
      expect(ids).to eq([older.id])
    end

    it "paginates with next_page" do
      followers = create_list(:user, 3).each { |follower| follower.follow(public_user) }

      get api_v1_user_followers_path(public_user, limit: 2), headers: headers
      expect(ids).to eq(followers.last(2).reverse.map(&:id))
      get api_v1_user_followers_path(public_user, limit: 2, page: response.parsed_body["next_page"]), headers: headers
      expect(ids).to eq([followers.first.id])
      expect(response.parsed_body["next_page"]).to be_nil
    end

    it "hides a private profile's lists from non-followers" do
      get api_v1_user_followers_path(private_user), headers: headers
      expect(response).to have_http_status(:forbidden)
      get api_v1_user_following_index_path(private_user), headers: headers
      expect(response).to have_http_status(:forbidden)

      user.follow(private_user).accept!
      get api_v1_user_followers_path(private_user), headers: headers
      expect(ids).to eq([user.id])
    end

    it "lets a private user see their own lists" do
      get api_v1_user_followers_path(private_user), headers: auth(private_user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "follow requests" do
    let(:private_headers) { auth(private_user) }

    before { user.follow(private_user) }

    it "lists pending requests" do
      get api_v1_me_follow_requests_path, headers: private_headers
      expect(ids).to eq([user.id])
    end

    it "approves a request" do
      post approve_api_v1_me_follow_request_path(user), headers: private_headers
      expect(response).to have_http_status(:no_content)
      expect(user).to be_following(private_user)
    end

    it "declines a request" do
      delete api_v1_me_follow_request_path(user), headers: private_headers
      expect(response).to have_http_status(:no_content)
      expect(Follow.count).to eq(0)
    end

    it "404s for users who haven't requested" do
      post approve_api_v1_me_follow_request_path(public_user), headers: private_headers
      expect(response).to have_http_status(:not_found)
    end

    it "approves all requests when the profile is made public" do
      patch api_v1_me_path, params: {user: {private_profile: false}}, headers: private_headers, as: :json
      expect(response.parsed_body["private_profile"]).to be(false)
      expect(user).to be_following(private_user)
    end
  end

  it "DELETE /api/v1/me/followers/:id removes a follower" do
    public_user.follow(user)
    delete api_v1_me_follower_path(public_user), headers: headers
    expect(response).to have_http_status(:no_content)
    expect(public_user).not_to be_following(user)
  end

  it "hides a private profile's recipes from non-followers" do
    recipe = create(:recipe, user: private_user)
    get api_v1_recipe_path(recipe), headers: headers
    expect(response).to have_http_status(:not_found)
    get api_v1_recipes_path(user_id: private_user.id), headers: headers
    expect(response.parsed_body["recipes"]).to be_empty

    user.follow(private_user).accept!
    get api_v1_recipe_path(recipe), headers: headers
    expect(response).to have_http_status(:ok)
  end
end
