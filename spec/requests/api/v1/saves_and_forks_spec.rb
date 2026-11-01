require "rails_helper"

RSpec.describe "API saves, popularity and forks", type: :request do
  let(:user) { create(:user) }
  let(:headers) { {Authorization: "Bearer #{create(:session, user: user).token}"} }
  let(:author) { create(:user) }
  let(:recipe) { create(:recipe, user: author) }

  def recipe_ids
    response.parsed_body["recipes"].map { |r| r["id"] }
  end

  describe "saving" do
    it "saves and unsaves a recipe, updating the count and saved flag" do
      post api_v1_recipe_save_path(recipe), headers: headers
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq("saved" => true, "saves_count" => 1)

      get api_v1_recipe_path(recipe), headers: headers
      expect(response.parsed_body).to include("saved" => true, "saves_count" => 1)

      delete api_v1_recipe_save_path(recipe), headers: headers
      expect(response).to have_http_status(:no_content)
      get api_v1_recipe_path(recipe), headers: headers
      expect(response.parsed_body).to include("saved" => false, "saves_count" => 0)
    end

    it "is harmless to save twice" do
      2.times { post api_v1_recipe_save_path(recipe), headers: headers }
      expect(response).to have_http_status(:ok)
      expect(recipe.reload.saves_count).to eq(1)
    end

    it "can't save a recipe the user can't see" do
      hidden = create(:recipe, :only_me, user: author)
      post api_v1_recipe_save_path(hidden), headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "marks saved recipes in lists" do
      other = create(:recipe, user: author)
      user.saved_recipes.create!(recipe: recipe)
      get api_v1_recipes_path, headers: headers
      saved = response.parsed_body["recipes"].to_h { |r| [r["id"], r["saved"]] }
      expect(saved).to eq(recipe.id => true, other.id => false)
    end
  end

  describe "GET /api/v1/me/saved_recipes" do
    it "lists saved recipes, most recently saved first, without hidden ones" do
      first, second, hidden = create_list(:recipe, 3, user: author)
      [second, first, hidden].each { |r| user.saved_recipes.create!(recipe: r) }
      hidden.update!(visibility: :only_me)

      get api_v1_me_saved_recipes_path, headers: headers
      expect(recipe_ids).to eq([first.id, second.id])
    end
  end

  describe "popular sort" do
    let!(:old_favorite) { create(:recipe, user: author) }
    let!(:new_hit) { create(:recipe, user: author) }
    let!(:unsaved) { create(:recipe, user: author) }

    before do
      create_list(:user, 3).each { |saver| saver.saved_recipes.create!(recipe: old_favorite, created_at: 2.months.ago) }
      create_list(:user, 2).each { |saver| saver.saved_recipes.create!(recipe: new_hit) }
    end

    it "sorts by all-time saves by default" do
      get api_v1_recipes_path(sort: "popular"), headers: headers
      expect(recipe_ids).to eq([old_favorite.id, new_hit.id, unsaved.id])
    end

    it "counts only saves within the period" do
      get api_v1_recipes_path(sort: "popular", period: "month"), headers: headers
      expect(recipe_ids).to eq([new_hit.id, unsaved.id, old_favorite.id])
    end

    it "paginates with next_page and combines with filters" do
      get api_v1_recipes_path(sort: "popular", limit: 2), headers: headers
      expect(recipe_ids).to eq([old_favorite.id, new_hit.id])
      expect(response.parsed_body["next_page"]).to be_a(String)

      get api_v1_recipes_path(sort: "popular", limit: 2, page: response.parsed_body["next_page"]), headers: headers
      expect(recipe_ids).to eq([unsaved.id])
      expect(response.parsed_body["next_page"]).to be_nil

      new_hit.update!(tags: ["quick"])
      get api_v1_recipes_path(sort: "popular", tags: "quick"), headers: headers
      expect(recipe_ids).to eq([new_hit.id])
    end

    it "rejects unknown sorts and periods" do
      get api_v1_recipes_path(sort: "random", period: "decade"), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"].keys).to contain_exactly("sort", "period")
    end
  end

  describe "POST /api/v1/recipes/:id/fork" do
    it "creates an only-me copy that links to the original" do
      recipe.update!(ingredient_lines: [{name: "rice", quantity: 1, unit: "cup"}])
      post api_v1_recipe_fork_path(recipe), headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include("title" => recipe.title, "visibility" => "only_me")
      expect(body["author"]["id"]).to eq(user.id)
      expect(body["ingredients"].map { |i| i["name"] }).to eq(["rice"])
      expect(body["forked_from"]).to include("id" => recipe.id, "title" => recipe.title)
      expect(body["photo"]).to include("default" => true)
    end

    it "can't fork a recipe the user can't see" do
      hidden = create(:recipe, :only_me, user: author)
      post api_v1_recipe_fork_path(hidden), headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "hides forked_from once the original is no longer visible" do
      fork = recipe.fork_for(user).tap(&:save!)
      recipe.update!(visibility: :only_me)

      get api_v1_recipe_path(fork), headers: headers
      expect(response.parsed_body["forked_from"]).to be_nil
    end
  end
end
