require "rails_helper"

RSpec.describe "API recipes", type: :request do
  let(:user) { create(:user) }
  let(:headers) { {Authorization: "Bearer #{create(:session, user: user).token}"} }
  let(:other_user) { create(:user) }

  let(:recipe_params) do
    {recipe: {
      title: "Pancakes", description: "Fluffy.", servings: 4, prep_minutes: 10, cook_minutes: 15,
      meal_type: "breakfast", difficulty: "easy", steps: ["Mix.", "Cook."],
      ingredients: [
        {name: "Flour", quantity: 2, unit: "cup"},
        {name: "Milk", quantity: 1.5, unit: "cup"},
        {name: "Eggs", quantity: 2, unit: "each"},
        {name: "Salt", note: "a pinch"}
      ]
    }}
  end

  it "requires authentication" do
    get api_v1_recipes_path
    expect(response).to have_http_status(:unauthorized)
  end

  describe "POST /api/v1/recipes" do
    it "creates a recipe with ingredients" do
      post api_v1_recipes_path, params: recipe_params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include("title" => "Pancakes", "servings" => 4, "total_minutes" => 25,
        "meal_type" => "breakfast", "visibility" => "public", "steps" => ["Mix.", "Cook."])
      expect(body["author"]).to eq("id" => user.id, "first_name" => user.first_name, "last_name" => user.last_name)
      expect(body["ingredients"].map { |i| i["name"] }).to eq(%w[flour milk eggs salt])
      expect(body["ingredients"].last).to include("quantity" => nil, "unit" => nil, "note" => "a pinch")
    end

    it "returns indexed errors for invalid ingredient lines" do
      recipe_params[:recipe][:ingredients][1][:unit] = "handful"
      post api_v1_recipes_path, params: recipe_params, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to eq("ingredients[1].unit" => ["is not included in the list"])
      expect(Recipe.count).to eq(0)
    end
  end

  describe "GET /api/v1/recipes/:id" do
    let(:recipe) do
      create(:recipe, user: other_user, servings: 4).tap do |r|
        r.update!(ingredient_lines: [{name: "flour", quantity: 2, unit: "cup"}, {name: "eggs", quantity: 2, unit: "each"}])
      end
    end

    it "shows quantities as written for a US customary reader" do
      get api_v1_recipe_path(recipe), headers: headers
      expect(response.parsed_body["ingredients"].first).to include("quantity" => 2.0, "unit" => "cup")
    end

    it "converts quantities for a metric reader, keeping the original" do
      user.update!(unit_system: :metric)
      get api_v1_recipe_path(recipe), headers: headers

      flour = response.parsed_body["ingredients"].first
      expect(flour).to include("quantity" => 473.0, "unit" => "ml", "original" => {"quantity" => 2.0, "unit" => "cup"})
    end

    it "scales quantities to the requested servings" do
      get api_v1_recipe_path(recipe, servings: 6), headers: headers

      body = response.parsed_body
      expect(body).to include("servings" => 6, "recipe_servings" => 4)
      expect(body["ingredients"].map { |i| [i["quantity"], i["unit"]] }).to eq([[3.0, "cup"], [3.0, "each"]])
    end

    it "ignores an invalid servings value" do
      get api_v1_recipe_path(recipe, servings: "lots"), headers: headers
      expect(response.parsed_body["servings"]).to eq(4)
    end

    it "hides another user's only-me recipe" do
      hidden = create(:recipe, :only_me, user: other_user)
      get api_v1_recipe_path(hidden), headers: headers
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Not found")
    end

    it "shows the user's own only-me recipe" do
      own = create(:recipe, :only_me, user: user)
      get api_v1_recipe_path(own), headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/recipes" do
    it "lists visible recipes newest first" do
      older = create(:recipe, user: other_user)
      own_private = create(:recipe, :only_me, user: user)
      create(:recipe, :only_me, user: other_user)

      get api_v1_recipes_path, headers: headers
      expect(response.parsed_body["recipes"].map { |r| r["id"] }).to eq([own_private.id, older.id])
      expect(response.parsed_body["next_cursor"]).to be_nil
    end

    it "paginates with a cursor" do
      recipes = create_list(:recipe, 5, user: other_user)

      get api_v1_recipes_path(limit: 2), headers: headers
      first_page = response.parsed_body
      expect(first_page["recipes"].map { |r| r["id"] }).to eq(recipes.last(2).reverse.map(&:id))

      get api_v1_recipes_path(limit: 2, before: first_page["next_cursor"]), headers: headers
      expect(response.parsed_body["recipes"].map { |r| r["id"] }).to eq(recipes[1..2].reverse.map(&:id))

      get api_v1_recipes_path(limit: 2, before: response.parsed_body["next_cursor"]), headers: headers
      expect(response.parsed_body["recipes"].map { |r| r["id"] }).to eq([recipes.first.id])
      expect(response.parsed_body["next_cursor"]).to be_nil
    end

    it "filters by author" do
      mine = create(:recipe, user: user)
      create(:recipe, user: other_user)

      get api_v1_recipes_path(user_id: user.id), headers: headers
      expect(response.parsed_body["recipes"].map { |r| r["id"] }).to eq([mine.id])
    end
  end

  describe "PATCH /api/v1/recipes/:id" do
    let(:recipe) { create(:recipe, user: user) }

    it "updates the recipe and replaces its ingredients" do
      recipe.update!(ingredient_lines: [{name: "flour", quantity: 1, unit: "cup"}])
      patch api_v1_recipe_path(recipe), headers: headers, as: :json,
        params: {recipe: {title: "Better", visibility: "only_me", ingredients: [{name: "sugar", quantity: 1, unit: "tbsp"}]}}

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("title" => "Better", "visibility" => "only_me")
      expect(response.parsed_body["ingredients"].map { |i| i["name"] }).to eq(["sugar"])
    end

    it "reports errors by position in the new list and keeps the old lines" do
      recipe.update!(ingredient_lines: [{name: "flour", quantity: 1, unit: "cup"}, {name: "milk", quantity: 1, unit: "cup"}])
      patch api_v1_recipe_path(recipe), headers: headers, as: :json,
        params: {recipe: {ingredients: [{name: "sugar", quantity: 1, unit: "handful"}]}}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to eq("ingredients[0].unit" => ["is not included in the list"])
      expect(recipe.reload.recipe_ingredients.map(&:name)).to eq(%w[flour milk])
    end

    it "keeps ingredients when they aren't sent" do
      recipe.update!(ingredient_lines: [{name: "flour", quantity: 1, unit: "cup"}])
      patch api_v1_recipe_path(recipe), params: {recipe: {title: "Renamed"}}, headers: headers, as: :json
      expect(response.parsed_body["ingredients"].map { |i| i["name"] }).to eq(["flour"])
    end

    it "removes all ingredients when an empty list is sent" do
      recipe.update!(ingredient_lines: [{name: "flour", quantity: 1, unit: "cup"}])
      patch api_v1_recipe_path(recipe), params: {recipe: {ingredients: []}}, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(recipe.reload.recipe_ingredients).to be_empty
    end

    it "can't update another user's public recipe" do
      theirs = create(:recipe, user: other_user)
      patch api_v1_recipe_path(theirs), params: {recipe: {title: "Mine now"}}, headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
      expect(theirs.reload.title).not_to eq("Mine now")
    end
  end

  describe "DELETE /api/v1/recipes/:id" do
    it "deletes the user's recipe and its ingredient lines" do
      recipe = create(:recipe, user: user)
      recipe.update!(ingredient_lines: [{name: "flour", quantity: 1, unit: "cup"}])

      delete api_v1_recipe_path(recipe), headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Recipe.exists?(recipe.id)).to be(false)
      expect(RecipeIngredient.count).to eq(0)
      expect(Ingredient.count).to eq(1)
    end

    it "can't delete another user's recipe" do
      theirs = create(:recipe, user: other_user)
      delete api_v1_recipe_path(theirs), headers: headers
      expect(response).to have_http_status(:not_found)
      expect(Recipe.exists?(theirs.id)).to be(true)
    end
  end
end
