require "rails_helper"

RSpec.describe "API discovery", type: :request do
  let(:user) { create(:user) }
  let(:headers) { {Authorization: "Bearer #{create(:session, user: user).token}"} }
  let(:author) { create(:user) }

  def recipe_ids
    response.parsed_body["recipes"].map { |r| r["id"] }
  end

  describe "GET /api/v1/recipes search and filters" do
    let!(:chili) do
      create(:recipe, user: author, title: "Black Bean Chili", meal_type: :dinner, difficulty: :easy,
        prep_minutes: 15, cook_minutes: 35, tags: %w[vegetarian budget]).tap do |r|
        r.update!(ingredient_lines: [{name: "black beans", quantity: 3, unit: "can"}])
      end
    end
    let!(:oats) do
      create(:recipe, user: author, title: "Overnight Oats", meal_type: :breakfast, difficulty: :easy,
        prep_minutes: 5, tags: %w[vegetarian no-cook])
    end
    let!(:fried_rice) do
      create(:recipe, user: author, title: "Chicken Fried Rice", meal_type: :dinner, difficulty: :medium,
        prep_minutes: 15, cook_minutes: 15, tags: %w[quick])
    end

    it "searches titles and ingredients" do
      get api_v1_recipes_path(q: "chicken"), headers: headers
      expect(recipe_ids).to eq([fried_rice.id])

      get api_v1_recipes_path(q: "beans"), headers: headers
      expect(recipe_ids).to eq([chili.id])
    end

    it "filters by meal type, difficulty and total time" do
      get api_v1_recipes_path(meal_type: "dinner", difficulty: "easy"), headers: headers
      expect(recipe_ids).to eq([chili.id])

      get api_v1_recipes_path(max_total_minutes: 30), headers: headers
      expect(recipe_ids).to eq([fried_rice.id, oats.id])
    end

    it "excludes recipes with no times from a time filter" do
      untimed = create(:recipe, user: author)
      get api_v1_recipes_path(max_total_minutes: 600), headers: headers
      expect(recipe_ids).not_to include(untimed.id)
    end

    it "filters by all given tags, as an array or comma-separated" do
      get api_v1_recipes_path(tags: %w[vegetarian budget]), headers: headers
      expect(recipe_ids).to eq([chili.id])

      get api_v1_recipes_path(tags: "Vegetarian, no-cook"), headers: headers
      expect(recipe_ids).to eq([oats.id])
    end

    it "combines search, filters and pagination" do
      get api_v1_recipes_path(tags: "vegetarian", limit: 1), headers: headers
      expect(recipe_ids).to eq([oats.id])
      get api_v1_recipes_path(tags: "vegetarian", limit: 1, page: response.parsed_body["next_page"]), headers: headers
      expect(recipe_ids).to eq([chili.id])
    end

    it "rejects invalid filter values" do
      get api_v1_recipes_path(meal_type: "brunch", difficulty: "extreme", max_total_minutes: "soon"), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"].keys).to contain_exactly("meal_type", "difficulty", "max_total_minutes")
    end

    it "never returns recipes the user can't see" do
      hidden = create(:recipe, :only_me, title: "Secret Chicken")
      private_author = create(:user, private_profile: true)
      create(:recipe, user: private_author, title: "Private Chicken")

      get api_v1_recipes_path(q: "chicken"), headers: headers
      expect(recipe_ids).to eq([fried_rice.id])
      expect(recipe_ids).not_to include(hidden.id)
    end

    it "accepts tags when creating a recipe" do
      post api_v1_recipes_path, params: {recipe: {title: "Toast", servings: 1, tags: ["Quick", "breakfast"]}},
        headers: headers, as: :json
      expect(response.parsed_body["tags"]).to eq(%w[quick breakfast])
    end
  end

  describe "GET /api/v1/feed" do
    it "shows public recipes from people the user follows, newest first" do
      followed = create(:user)
      user.follow(followed)
      older = create(:recipe, user: followed)
      newer = create(:recipe, user: followed)
      create(:recipe, :only_me, user: followed)
      create(:recipe, user: user)
      create(:recipe, user: create(:user))

      get api_v1_feed_path, headers: headers
      expect(recipe_ids).to eq([newer.id, older.id])
    end

    it "includes approved private profiles but not pending requests or deactivated users" do
      approved = create(:user, private_profile: true)
      pending = create(:user, private_profile: true)
      gone = create(:user)
      user.follow(approved).accept!
      user.follow(pending)
      user.follow(gone)
      visible = create(:recipe, user: approved)
      create(:recipe, user: pending)
      create(:recipe, user: gone)
      gone.deactivate!

      get api_v1_feed_path, headers: headers
      expect(recipe_ids).to eq([visible.id])
    end

    it "is empty for a user who follows nobody" do
      create(:recipe, user: author)
      get api_v1_feed_path, headers: headers
      expect(response.parsed_body).to eq("recipes" => [], "next_page" => nil)
    end
  end

  describe "GET /api/v1/users" do
    it "finds active users by name" do
      ada = create(:user, first_name: "Ada", last_name: "Lovelace")
      create(:user, first_name: "Grace", last_name: "Hopper")
      create(:user, first_name: "Ada", last_name: "Gone").deactivate!

      get api_v1_users_path(q: "ada love"), headers: headers
      expect(response.parsed_body["users"].map { |u| u["id"] }).to eq([ada.id])

      get api_v1_users_path(q: "LOVE"), headers: headers
      expect(response.parsed_body["users"].map { |u| u["id"] }).to eq([ada.id])
    end

    it "treats % and _ literally" do
      create(:user, first_name: "Ada", last_name: "Lovelace")
      get api_v1_users_path(q: "%"), headers: headers
      expect(response.parsed_body["users"]).to be_empty
    end

    it "requires a query" do
      get api_v1_users_path, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
