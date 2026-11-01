require "rails_helper"

RSpec.describe "Api::V1::Recipes", type: :request do
  before(:all) do
    @user = create(:user)
    create(:recipe, user: @user)
    create(:recipe, user: @user)
  end

  describe "GET /index" do
    it "retrieve all recipes" do
      get api_v1_recipes_path
      expect(response).to have_http_status(:success)
      expect(@user.recipes.count).to eq(2)
    end
  end

  describe "GET /show" do
    let(:owner) { create(:user) }
    let(:private_recipe) { create(:recipe, user: owner, is_private: true) }
    let(:public_recipe) { create(:recipe, user: owner, is_private: false) }

    it "shows a public recipe without a token" do
      get api_v1_recipe_path(public_recipe)
      expect(response).to have_http_status(:ok)
    end

    it "hides a private recipe without a token" do
      get api_v1_recipe_path(private_recipe)
      expect(response).to have_http_status(:not_found)
    end

    it "hides a private recipe from other users" do
      token = create(:api_token, user: create(:user)).token
      get api_v1_recipe_path(private_recipe), headers: {Authorization: "Bearer #{token}"}
      expect(response).to have_http_status(:not_found)
    end

    it "shows a private recipe to its owner" do
      token = create(:api_token, user: owner).token
      get api_v1_recipe_path(private_recipe), headers: {Authorization: "Bearer #{token}"}
      expect(response).to have_http_status(:ok)
    end
  end
end
